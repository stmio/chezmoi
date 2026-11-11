# EGUI Layout Guide — Common Patterns and Fixes

Reference for diagnosing and fixing EGUI layout/design issues. Organized by problem
category so you can jump to the relevant section after analyzing a screenshot.

## Table of Contents

1. [Panel Structure](#panel-structure)
2. [Layout Direction](#layout-direction)
3. [Spacing and Margins](#spacing-and-margins)
4. [Sizing Widgets](#sizing-widgets)
5. [Text and Labels](#text-and-labels)
6. [Scrolling](#scrolling)
7. [Grids and Tables](#grids-and-tables)
8. [Frames and Containers](#frames-and-containers)
9. [Alignment](#alignment)
10. [Responsive Layout](#responsive-layout)
11. [Styling and Visuals](#styling-and-visuals)
12. [Common Gotchas](#common-gotchas)

---

## Panel Structure

Panels are the top-level layout primitive. They claim screen space from the edges
inward, leaving whatever remains for `CentralPanel`.

**Critical rule:** All `SidePanel` and `TopBottomPanel` calls must come BEFORE
`CentralPanel`. If you add a panel after `CentralPanel`, it won't have any space.

```rust
// CORRECT order:
egui::TopBottomPanel::top("menu_bar").show(ctx, |ui| { /* ... */ });
egui::SidePanel::left("sidebar").show(ctx, |ui| { /* ... */ });
egui::CentralPanel::default().show(ctx, |ui| { /* ... */ });

// WRONG — bottom panel has no space:
egui::CentralPanel::default().show(ctx, |ui| { /* ... */ });
egui::TopBottomPanel::bottom("status").show(ctx, |ui| { /* ... */ });
```

### Panel sizing

```rust
// Fixed width sidebar
SidePanel::left("sidebar")
    .exact_width(200.0)
    .show(ctx, |ui| { /* ... */ });

// Resizable sidebar with limits
SidePanel::left("sidebar")
    .resizable(true)
    .default_width(250.0)
    .width_range(150.0..=400.0)
    .show(ctx, |ui| { /* ... */ });

// Fixed height top bar
TopBottomPanel::top("toolbar")
    .exact_height(40.0)
    .show(ctx, |ui| { /* ... */ });
```

### Common panel problems

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Panel is invisible / zero size | Added after CentralPanel | Reorder: side/top panels first |
| Content overflows panel | No ScrollArea inside panel | Wrap content in `ScrollArea::vertical()` |
| Panel flickers or resizes every frame | Content size changes each frame | Use `exact_width()` or `min_width()` |
| Two sidebars overlap | Both use `SidePanel::left` | Use `left` for one, `right` for the other |

---

## Layout Direction

EGUI lays out widgets in a single direction within each `ui` scope — either vertical
(default) or horizontal.

```rust
// Vertical (default) — widgets stack top to bottom
ui.vertical(|ui| {
    ui.label("First");
    ui.label("Second");  // below First
});

// Horizontal — widgets flow left to right
ui.horizontal(|ui| {
    ui.label("Left");
    ui.label("Right");  // to the right of Left
});

// Horizontal wrapping — wraps to next line when out of space
ui.horizontal_wrapped(|ui| {
    for tag in &tags {
        ui.label(tag);
    }
});
```

### Nesting layouts

```rust
ui.horizontal(|ui| {
    ui.label("Name:");
    ui.vertical(|ui| {
        ui.text_edit_singleline(&mut self.first_name);
        ui.text_edit_singleline(&mut self.last_name);
    });
});
```

### Centering content

```rust
// Center horizontally
ui.vertical_centered(|ui| {
    ui.heading("Centered Title");
});

// Center a single widget horizontally
ui.with_layout(egui::Layout::top_down(egui::Align::Center), |ui| {
    ui.label("Centered");
});

// Center vertically (requires knowing available height)
let available = ui.available_height();
ui.add_space(available / 2.0 - 20.0); // rough centering
ui.label("Vertically centered-ish");
```

---

## Spacing and Margins

### Between widgets

```rust
// Add explicit space
ui.add_space(16.0);

// Change spacing for all widgets in this ui scope
ui.spacing_mut().item_spacing = egui::vec2(8.0, 4.0); // (horizontal, vertical)

// Separator line between sections
ui.separator();
```

### Global spacing via Style

```rust
// In your app setup or update():
let mut style = (*ctx.style()).clone();
style.spacing.item_spacing = egui::vec2(8.0, 6.0);
style.spacing.window_padding = egui::vec2(12.0, 12.0);
style.spacing.button_padding = egui::vec2(8.0, 4.0);
style.spacing.indent = 24.0;
ctx.set_style(style);
```

### Key spacing properties

- `item_spacing` — gap between consecutive widgets (default: `[8.0, 3.0]`)
- `window_padding` — padding inside windows/panels
- `button_padding` — internal padding of buttons
- `indent` — indentation for `ui.indent()`
- `interact_size` — minimum interactive widget size (click targets)
- `combo_width` — default width of combo boxes
- `text_edit_width` — default width of text inputs

---

## Sizing Widgets

### Fixed and flexible sizing

```rust
// Fixed size button
let btn = egui::Button::new("Click me").min_size(egui::vec2(120.0, 40.0));
ui.add(btn);

// Full-width widget
ui.add_sized([ui.available_width(), 30.0], egui::TextEdit::singleline(&mut text));

// Full-width button
if ui.add_sized([ui.available_width(), 0.0], egui::Button::new("Wide Button")).clicked() {
    // ...
}

// Allocate specific space then put widget there
let (rect, _response) = ui.allocate_exact_size(egui::vec2(200.0, 100.0), egui::Sense::hover());
ui.put(rect, egui::Label::new("Placed exactly"));
```

### Limiting sizes

```rust
// Set max width for a region
ui.set_max_width(400.0);

// Set min height
ui.set_min_height(200.0);

// Set both
ui.set_min_size(egui::vec2(300.0, 200.0));
ui.set_max_size(egui::vec2(600.0, 400.0));
```

### Expanding to fill

```rust
// Make a widget fill available width
ui.with_layout(egui::Layout::top_down_justified(egui::Align::LEFT), |ui| {
    ui.button("This fills the width");
    ui.button("So does this");
});
```

---

## Text and Labels

### Truncated text fix

```rust
// Problem: long text is clipped
ui.label("Very long text that gets cut off...");

// Fix 1: Wrap text
ui.label(egui::RichText::new("Long text...").size(14.0));
ui.add(egui::Label::new("Long text...").wrap());  // explicit wrap

// Fix 2: Use available width
ui.add_sized(
    [ui.available_width(), 0.0],
    egui::Label::new("Long text that now has room").wrap(),
);

// Fix 3: Truncate gracefully (shows ... at end)
ui.add(egui::Label::new("Long text...").truncate());
```

### Font sizes

```rust
ui.label(egui::RichText::new("Heading").size(24.0).strong());
ui.label(egui::RichText::new("Body text").size(14.0));
ui.label(egui::RichText::new("Caption").size(11.0).weak());

// Monospace
ui.label(egui::RichText::new("code").monospace());
```

---

## Scrolling

### Basic scroll areas

```rust
// Vertical scroll
egui::ScrollArea::vertical().show(ui, |ui| {
    for i in 0..100 {
        ui.label(format!("Item {}", i));
    }
});

// Horizontal scroll
egui::ScrollArea::horizontal().show(ui, |ui| {
    ui.horizontal(|ui| {
        for i in 0..50 {
            ui.button(format!("Btn {}", i));
        }
    });
});

// Both directions
egui::ScrollArea::both().show(ui, |ui| { /* ... */ });
```

### Scroll area sizing

```rust
// Fixed height scroll area
egui::ScrollArea::vertical()
    .max_height(300.0)
    .show(ui, |ui| { /* ... */ });

// Auto-shrink: by default, ScrollArea expands to fill. To make it shrink-wrap:
egui::ScrollArea::vertical()
    .auto_shrink([false, true])  // [horizontal, vertical]
    .show(ui, |ui| { /* ... */ });
```

### Common scroll problems

| Symptom | Cause | Fix |
|---------|-------|-----|
| Double scrollbar | ScrollArea inside a panel that also scrolls | Remove one ScrollArea or use `.auto_shrink(false)` |
| Content not scrollable | ScrollArea has no height constraint | Set `.max_height()` or put inside a sized container |
| Scroll area is tiny | Content is small and `auto_shrink` is true | Set `auto_shrink([false, false])` |
| Horizontal scroll appearing unexpectedly | Content slightly wider than container | Check for padding/margin that pushes content out |

---

## Grids and Tables

### egui::Grid (for aligned forms/key-value layouts)

```rust
egui::Grid::new("my_grid")
    .num_columns(2)
    .spacing([40.0, 4.0])  // [column gap, row gap]
    .striped(true)
    .show(ui, |ui| {
        ui.label("Name:");
        ui.text_edit_singleline(&mut self.name);
        ui.end_row();

        ui.label("Email:");
        ui.text_edit_singleline(&mut self.email);
        ui.end_row();

        ui.label("Role:");
        egui::ComboBox::from_id_salt("role")
            .selected_text(&self.role)
            .show_ui(ui, |ui| {
                ui.selectable_value(&mut self.role, "Admin".into(), "Admin");
                ui.selectable_value(&mut self.role, "User".into(), "User");
            });
        ui.end_row();
    });
```

**Critical:** Always call `ui.end_row()` after each row. Missing `end_row()` causes
all widgets to pile into one row.

### egui_extras::TableBuilder (for data tables)

```rust
use egui_extras::{TableBuilder, Column};

TableBuilder::new(ui)
    .striped(true)
    .resizable(true)
    .column(Column::auto().at_least(100.0))     // Name
    .column(Column::initial(80.0).resizable(true)) // Age
    .column(Column::remainder())                 // Email (fills remaining)
    .header(20.0, |mut header| {
        header.col(|ui| { ui.strong("Name"); });
        header.col(|ui| { ui.strong("Age"); });
        header.col(|ui| { ui.strong("Email"); });
    })
    .body(|mut body| {
        for person in &self.people {
            body.row(18.0, |mut row| {
                row.col(|ui| { ui.label(&person.name); });
                row.col(|ui| { ui.label(person.age.to_string()); });
                row.col(|ui| { ui.label(&person.email); });
            });
        }
    });
```

### StripBuilder (precise row/column sizing)

```rust
use egui_extras::{StripBuilder, Size};

StripBuilder::new(ui)
    .size(Size::exact(40.0))       // toolbar: fixed 40px
    .size(Size::remainder())        // content: fills remaining space
    .size(Size::exact(24.0))       // status bar: fixed 24px
    .vertical(|mut strip| {
        strip.cell(|ui| { ui.label("Toolbar"); });
        strip.cell(|ui| { ui.label("Content area"); });
        strip.cell(|ui| { ui.label("Status bar"); });
    });
```

---

## Frames and Containers

### Adding padding/borders around content

```rust
egui::Frame::none()
    .inner_margin(egui::Margin::same(12.0))
    .outer_margin(egui::Margin::same(4.0))
    .stroke(ui.visuals().widgets.noninteractive.bg_stroke)
    .rounding(4.0)
    .fill(ui.visuals().extreme_bg_color)
    .show(ui, |ui| {
        ui.label("Content with border and padding");
    });

// Asymmetric margins
egui::Frame::none()
    .inner_margin(egui::Margin {
        left: 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 8.0,
    })
    .show(ui, |ui| { /* ... */ });
```

### Collapsing headers (accordion sections)

```rust
egui::CollapsingHeader::new("Advanced Settings")
    .default_open(false)
    .show(ui, |ui| {
        ui.label("Hidden content");
    });
```

### Group (simple bordered container)

```rust
ui.group(|ui| {
    ui.label("Grouped content");
    ui.button("In the same box");
});
```

---

## Alignment

### Right-align in a horizontal layout

```rust
ui.horizontal(|ui| {
    ui.label("Left side");
    // Push everything after this to the right
    ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
        ui.button("Right side");
    });
});
```

### Bottom-align content

```rust
ui.with_layout(egui::Layout::bottom_up(egui::Align::LEFT), |ui| {
    ui.label("This sticks to the bottom");
    // Note: items added here stack upward from the bottom
});
```

### Centering a widget in available space

```rust
ui.with_layout(
    egui::Layout::centered_and_justified(egui::Direction::TopDown),
    |ui| {
        ui.label("Dead center");
    },
);
```

---

## Responsive Layout

### Adapting to window size

```rust
let available_width = ui.available_width();

if available_width > 600.0 {
    // Wide layout: side by side
    ui.horizontal(|ui| {
        ui.group(|ui| {
            ui.set_width(available_width * 0.5 - 8.0);
            ui.label("Left panel content");
        });
        ui.group(|ui| {
            ui.set_width(available_width * 0.5 - 8.0);
            ui.label("Right panel content");
        });
    });
} else {
    // Narrow layout: stacked
    ui.group(|ui| { ui.label("Top content"); });
    ui.group(|ui| { ui.label("Bottom content"); });
}
```

### Checking available space

```rust
let width = ui.available_width();
let height = ui.available_height();
let rect = ui.available_rect_before_wrap();
let size = ui.available_size();
```

---

## Styling and Visuals

### Changing colors

```rust
// Global style changes
let mut visuals = egui::Visuals::dark(); // or ::light()
visuals.override_text_color = Some(egui::Color32::from_rgb(200, 200, 200));
visuals.widgets.noninteractive.bg_fill = egui::Color32::from_rgb(30, 30, 30);
ctx.set_visuals(visuals);

// Per-widget color
ui.colored_label(egui::Color32::RED, "Error message");
ui.label(egui::RichText::new("Warning").color(egui::Color32::YELLOW));
```

### Custom widget styling

```rust
// Styled button
let button = egui::Button::new(
    egui::RichText::new("Primary Action").size(16.0).strong()
)
.fill(egui::Color32::from_rgb(0, 120, 212))
.rounding(6.0)
.min_size(egui::vec2(140.0, 36.0));

if ui.add(button).clicked() { /* ... */ }
```

---

## Common Gotchas

### 1. Widgets disappear or have zero size
The parent container has no space left. Check that `CentralPanel` is last, and that
parent containers have enough height/width. Use `ui.available_size()` to debug.

### 2. Layout breaks when window is resized
Hardcoded pixel positions or sizes. Replace with `ui.available_width()` and
proportional sizing.

### 3. Grid columns misalign
Missing `ui.end_row()` call. Every row must end with it.

### 4. ComboBox or menu appears behind other widgets
Z-ordering issue. Menus and popups in EGUI use `Area` which renders on top, but
custom overlays may conflict. Avoid drawing over the popup area.

### 5. Text input doesn't respond to clicks
Another transparent widget is intercepting the click. Check for overlapping `Sense`
areas. Use the EGUI debug inspector (`ctx.set_debug_on_hover(true)`) to visualize
widget bounds.

### 6. Performance degrades with many widgets
EGUI redraws everything each frame. For large lists, use `ScrollArea` with
`show_rows()` for virtual scrolling:

```rust
let row_height = 18.0;
let total_rows = self.items.len();
egui::ScrollArea::vertical().show_rows(ui, row_height, total_rows, |ui, row_range| {
    for i in row_range {
        ui.label(&self.items[i]);
    }
});
```

### 7. Debug inspector

Enable the built-in debug overlay to see widget bounds and IDs:

```rust
// In update():
ctx.set_debug_on_hover(true);
// Now hover over any widget to see its rect, id, and layout info
```

This is invaluable for diagnosing spacing and alignment issues — it shows you exactly
where EGUI thinks each widget's bounding box is.
