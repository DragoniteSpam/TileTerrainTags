var ew = 320;
var eh = 32;
var spacing = 32;
var c1 = spacing;
var c2 = c1 + ew + spacing;
var c3 = room_width - spacing - ew;

self.tags = array_create(63, "");
self.tags[0] = "Solid";
self.tags[1] = "Shallow Water";
self.tags[2] = "Deep Water";

self.image = undefined;
self.cell_width = 32;
self.cell_height = 32;
self.cell = -1;
self.cell_values = [];
self.last_file_name = "";

self.cell_copy_mask = -1;

self.SelectCell = function(x, y) {
    if (!sprite_exists(self.image)) return;
    self.cell = x + y * (sprite_get_width(self.image) div self.cell_width);
    self.container.GetChild("CELL")
        .SetInteractive(true)
        .Refresh();
};

self.GetCellIndex = function(x, y) {
    return x + y * (sprite_get_width(self.image) div self.cell_width);
};

self.GetSelectedCellValue = function() {
    if (self.cell == -1) return 0;
    return self.cell_values[self.cell];
};

self.SetSelectedCellValue = function(value) {
    if (self.cell == -1) return;
    self.cell_values[self.cell] = value;
};

self.GetCellValue = function(x, y) {
    return self.cell_values[x + y * (sprite_get_width(self.image) div self.cell_width)];
};

self.SetCellValue = function(x, y, value) {
    self.cell_values[x + y * (sprite_get_width(self.image) div self.cell_width)] = value;
};

self.CopyCellMask = function() {
    if (self.cell == -1) return;
    self.cell_copy_mask = self.GetSelectedCellValue();
};

self.PasteCellMask = function() {
    if (self.cell == -1) return;
    if (self.cell_copy_mask == -1) return;
    self.SetSelectedCellValue(self.cell_copy_mask);
    self.container.GetChild("CELL")
        .SetInteractive(true)
        .Refresh();
};

self.ResetCellMask = function() {
    if (self.cell == -1) return;
    self.SetSelectedCellValue(0);
};

self.LoadImage = function(filename) {
    if (sprite_exists(self.image)) sprite_delete(self.image);
    self.image = sprite_add(filename, 0, false, false, 0, 0);
    self.cell = -1;
    if (filename != "auto.png") {
        self.last_file_name = filename;
    }
    var path_hash = sha1_string_utf8(filename);
    var w = 32;
    var h = 32;
    var location = path_hash;
    if (file_exists(location)) {
        var b = buffer_load(location);
        w = buffer_read(b, buffer_u32);
        h = buffer_read(b, buffer_u32);
        buffer_delete(b);
    }
    self.ResetCellData(w, h);
};

self.SaveImageMetadata = function(filename, destination) {
    var b = buffer_create(10, buffer_grow, 1);
    buffer_write(b, buffer_u32, self.cell_width);
    buffer_write(b, buffer_u32, self.cell_height);
    buffer_write(b, buffer_string, filename);
    buffer_save_ext(b, destination, 0, buffer_tell(b));
    buffer_delete(b);
};

self.ResetCellData = function(w = self.cell_width, h = self.cell_height) {
    self.cell_width = w;
    self.cell_height = h;
    self.cell_values = array_create((sprite_get_width(self.image) div w) * (sprite_get_height(self.image) div h), 0);
};

self.ExportTags = function(filename) {
    var buffer = buffer_create(1000, buffer_grow, 1);
    array_foreach(self.cell_values, method({ buffer }, function(tag) {
        buffer_write(self.buffer, buffer_u64, tag);
    }));
    buffer_save_ext(buffer, filename, 0, buffer_tell(buffer));
    buffer_delete(buffer);
};

self.ImportTags = function(filename) {
    var buffer = buffer_load(filename);
    
    for (var i = 0, n = min(array_length(self.cell_values), buffer_get_size(buffer) / buffer_sizeof(buffer_u64)); i < n; i++) {
        self.cell_values[i] = buffer_read(buffer, buffer_u64);
    }
    
    var old_size = array_length(self.cell_values);
    
    array_resize(self.cell_values, (sprite_get_width(self.image) div self.cell_width) * (sprite_get_height(self.image) div self.cell_height));
    
    if (array_length(self.cell_values) > old_size) {
        array_map_ext(self.cell_values, function() {
            return 0;
        }, old_size, array_length(self.cell_values) - old_size);
    }
    
    buffer_delete(buffer);
};

self.SaveTags = function(filename) {
    var buffer = buffer_create(1000, buffer_grow, 1);
    array_foreach(self.tags, method({ buffer }, function(tag) {
        buffer_write(self.buffer, buffer_text, tag + "\n");
    }));
    buffer_save_ext(buffer, filename, 0, buffer_tell(buffer));
    buffer_delete(buffer);
};

self.LoadTags = function(filename) {
    var buffer = buffer_load(filename);
    array_map_ext(self.tags, function() {
        return "";
    });
    var new_tags = string_split(buffer_read(buffer, buffer_text), "\n");
    for (var i = 0, n = min(array_length(new_tags), array_length(obj_demo.tags)); i < n; i++) {
        obj_demo.tags[i] = new_tags[i];
    }
    buffer_delete(buffer);
    self.container.GetChild("TAGS").ClearSelection();
};

self.Hexify = function(value) {
    if (value == 0) return "0";
    var hex = string(ptr(value));
    while (string_starts_with(hex, "0") && string_length(hex) > 1) {
        hex = string_copy(hex, 2, string_length(hex) - 1);
    }
    return hex;
};

self.container = new EmuCore(0, 0, room_width, room_height).AddContent([
    new EmuText(c1, EMU_AUTO, ew, eh, "[c_aqua]Tile Terrain Tags"),
    new EmuButton(c1, EMU_AUTO, ew, eh, "Load Image", function() {
        var filename = get_open_filename("Image files|*.png", "tileset.png");
        if (file_exists(filename)) {
            obj_demo.LoadImage(filename);
        }
    }),
    new EmuButton(c1, EMU_AUTO, ew, eh, "Save Tags", function() {
        var filename = get_save_filename("Text files|*.txt", "tags.txt");
        if (filename != "") {
            obj_demo.SaveTags(filename);
        }
    }),
    new EmuButton(c1, EMU_AUTO, ew, eh, "Load Tags", function() {
        var filename = get_open_filename("Text files|*.txt", "tags.txt");
        if (file_exists(filename)) {
            obj_demo.LoadTags(filename);
        }
    }),
    new EmuButton(c1, EMU_AUTO, ew, eh, "Import Tag Data", function() {
        var filename = get_open_filename("Terrain tag files|*.tag", "terrain.tag");
        if (file_exists(filename)) {
            obj_demo.ImportTags(filename);
        }
    }),
    new EmuButton(c1, EMU_AUTO, ew, eh, "Export Tag Data", function() {
        var filename = get_save_filename("Terrain tag files|*.tag", "terrain.tag");
        if (filename != "") {
            obj_demo.ExportTags(filename);
        }
    }),
    new EmuText(c1, EMU_AUTO, ew, eh, "Tile size:"),
    new EmuInput(c1, EMU_AUTO, ew / 2, eh, "", string(self.cell_width), "tile width", 3, E_InputTypes.INT, function() {
        obj_demo.cell_width = real(self.value);
        obj_demo.ResetCellData();
    })
        .SetRequireConfirm(true)
        .SetInputBoxPosition(0, 0),
    new EmuInput(c1 + ew / 2, EMU_INLINE, ew / 2, eh, "", string(self.cell_width), "tile height", 3, E_InputTypes.INT, function() {
        obj_demo.cell_height= real(self.value);
        obj_demo.ResetCellData();
    })
        .SetRequireConfirm(true)
        .SetInputBoxPosition(0, 0),
    new EmuList(c1, EMU_AUTO, ew, eh, "Tags:", eh, 12, function() {
        var selection = self.GetSelection();
        if (selection != -1) {
            self.GetSibling("NAME").SetValue(obj_demo.tags[selection]);
        }
    })
        .SetNumbered(true)
        .SetList(self.tags)
        .SetID("TAGS"),
    new EmuInput(c1, EMU_AUTO, ew, eh, "Name:", "", "Terrain tag name", 32, E_InputTypes.STRING, function() {
        var selection = self.GetSibling("TAGS").GetSelection();
        obj_demo.tags[selection] = self.value;
    })
        .SetInputBoxPosition(ew / 3, 0)
        .SetUpdate(function() {
            var has_selection = self.GetSibling("TAGS").GetSelection() != -1;
            self.SetInteractive(array_length(obj_demo.tags) > 0 && has_selection);
        })
        .SetID("NAME"),
    new EmuRenderSurface(c2, EMU_BASE, room_width - c2 - spacing * 2 - ew, room_height - spacing * 2, function(mx, my) {
        // render
        var spr = obj_demo.image;
        var w = obj_demo.cell_width;
        var h = obj_demo.cell_height;
        
        self.drawCheckerbox(0, 0);
        
        var xc_hover = -1;
        var yc_hover = -1;
        var xc = -1;
        var yc = -1;
        
        matrix_set(matrix_world, matrix_build(-self.xoff, -self.yoff, 0, 0, 0, 0, self.zoom, self.zoom, 1));
        if (sprite_exists(spr)) {
            var sw = sprite_get_width(spr);
            var sh = sprite_get_height(spr);
            var hc = sw div w;
            var vc = sh div h;
            
            draw_sprite(spr, 0, 0, 0);
            for (var xx = 0; xx <= sw; xx += w) {
                draw_line_colour(xx - 1, 0, xx - 1, sh - 1, c_black, c_black);
            }
            for (var yy = 0; yy <= sh; yy += h) {
                draw_line_colour(0, yy - 1, sw - 1, yy - 1, c_black, c_black);
            }
            
            if (mx >= 0 && my >= 0 && mx < self.width && my < self.height) {
                // deal with the highlighted cell
                mx += self.xoff;
                my += self.yoff;
                mx /= self.zoom;
                my /= self.zoom;
                
                xc_hover = mx div w;
                yc_hover = my div h;
                
                if (xc_hover >= 0 && yc_hover >= 0 && xc_hover < hc && yc_hover < vc) {
                    if (mouse_check_button_pressed(mb_left)) {
                        obj_demo.SelectCell(xc_hover, yc_hover);
                    }
                    if (mouse_check_button_pressed(mb_right)) {
                        obj_demo.SelectCell(xc_hover, yc_hover);
                        obj_demo.PasteCellMask();
                    }
                    
                    var x1 = xc_hover * w;
                    var y1 = yc_hover * h;
                    
                    draw_sprite_stretched_ext(spr_highlight, 0, x1, y1, w, h, c_green, 1);
                }
            }
            
            // draw the currently-selected cell
            if (obj_demo.cell != -1) {
                xc = obj_demo.cell mod hc;
                yc = obj_demo.cell div hc;
                var x1 = xc * w;
                var y1 = yc * h;
                
                draw_sprite_stretched_ext(spr_highlight, 0, x1, y1, w, h, c_blue, 1);
            }
            
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_font(fnt_output);
            
            // draw the readouts
            for (var i = 0; i < hc; i++) {
                for (var j = 0; j < vc; j++) {
                    var xx = i * w + w / 2;
                    var yy = j * h + h / 2;
                    var text_color = (xc == i && yc == j) ? #3399ff : c_white;
                    var text_alpha = ((xc == i && yc == j) || (xc_hover == i && yc_hover == j)) ? 0.9 : 0.55;
                    var output = obj_demo.Hexify(obj_demo.GetCellValue(i, j));
                    var output_with_line_breaks = "";
                    
                    var text_scale = 1 / 4;
                    var text_stride = 4;
                    
                    var len = string_length(output);
                    if (len > 8) {
                        text_scale = 1 / 6;
                        text_stride = 6;
                    }
                    
                    for (var c = 1; c <= len; c++) {
                        output_with_line_breaks += string_char_at(output, c);
                        if (c % text_stride == 0) {
                            output_with_line_breaks += "\n";
                        }
                    }
                    draw_text_transformed_color(xx, yy, output_with_line_breaks, text_scale, text_scale, 0, text_color, text_color, text_color, text_color, text_alpha);
                }
            }
        }
        
        matrix_set(matrix_world, matrix_build_identity());
    }, function(mx, my) {
        // step
        if (mx < 0 || my < 0 || mx >= self.width || my >= self.height) return;
        
        static scroll_step = 16;
        static zoom_step = 0.125;
        var scroll_value = scroll_step * self.zoom;
        if (mouse_wheel_up()) {
            if (keyboard_check(vk_shift)) {
                self.xoff -= scroll_value;
            } else if (keyboard_check(vk_control)) {
                self.zoom = min(4, self.zoom + zoom_step);
            } else {
                self.yoff -= scroll_value;
            }
        }
        if (mouse_wheel_down()) {
            if (keyboard_check(vk_shift)) {
                self.xoff += scroll_value;
            } else if (keyboard_check(vk_control)) {
                self.zoom = max(1, self.zoom - zoom_step);
            } else {
                self.yoff += scroll_value;
            }
        }
        if (keyboard_check(vk_tab)) {
            self.xoff = 0;
            self.yoff = 0;
            self.zoom = 1;
        }
    }, function() {
        self.xoff = 0;
        self.yoff = 0;
        self.zoom = 1;
    }),
    new EmuText(c3, EMU_BASE, ew, eh, "Select a tile...")
        .SetUpdate(function() {
            if (obj_demo.cell == -1 || !sprite_exists(obj_demo.image)) {
                self.text = "Select a tile...";
            } else {
                var hc = sprite_get_width(obj_demo.image) div obj_demo.cell_width;
                var vc = sprite_get_height(obj_demo.image) div obj_demo.cell_height;
                self.text = $"Data for Tile {obj_demo.cell} ({obj_demo.cell mod hc}, {obj_demo.cell div hc})";
            }
        }),
    new EmuText(c3, EMU_AUTO, ew, eh, "Mask: n/a")
        .SetUpdate(function() {
            if (obj_demo.cell == -1 || !sprite_exists(obj_demo.image)) {
                self.text = "Mask: n/a";
            } else {
                var value = obj_demo.GetSelectedCellValue();
                self.text = $"Mask: {value == 0 ? "0" : string(ptr(value))}";
            }
        }),
    new EmuList(c3, EMU_AUTO, ew, eh, "Values:", eh, 18, function() {
        var mask = array_reduce(self.GetAllSelectedItems(), function(previous, value) {
            return previous | power(2, array_get_index(obj_demo.tags, value));
        }, 0);
        obj_demo.SetSelectedCellValue(mask);
    })
        .SetNumbered(true)
        .SetUpdate(function() {
            self.SetInteractive(obj_demo.cell != -1 && sprite_exists(obj_demo.image));
        })
        .SetRefresh(function() {
            if (!self.interactive) return;
            var value = obj_demo.GetSelectedCellValue();
            self.ClearSelection();
            var n = 0;
            while (value != 0) {
                if (value & 1 == 1) {
                    self.Select(n);
                }
                n++;
                value = value >> 1;
            }
        })
        .SetList(self.tags)
        .SetID("CELL")
        .SetMultiSelect(true, true, true, true),
    new EmuButton(c3, EMU_AUTO, ew, eh, "Copy mask", function() {
        obj_demo.CopyCellMask();
    })
        .SetUpdate(function() {
            self.SetInteractive(obj_demo.cell != -1 && sprite_exists(obj_demo.image));
        }),
    new EmuButton(c3, EMU_AUTO, ew, eh, "Paste mask", function() {
        obj_demo.PasteCellMask();
    })
        .SetUpdate(function() {
            self.SetInteractive(obj_demo.cell != -1 && sprite_exists(obj_demo.image));
        }),
    new EmuButton(c3, EMU_AUTO, ew, eh, "Clear mask", function() {
        obj_demo.ResetCellMask();
    })
        .SetUpdate(function() {
            self.SetInteractive(obj_demo.cell != -1 && sprite_exists(obj_demo.image));
        })
]);

// load the autosaved grid size first
if (file_exists("auto")) {
    var b = buffer_load("auto");
    self.cell_width = buffer_read(b, buffer_u32);
    self.cell_height = buffer_read(b, buffer_u32);
    buffer_delete(b);
}
if (file_exists("auto.txt")) {
    self.LoadTags("auto.txt");
}
if (file_exists("auto.png")) {
    self.LoadImage("auto.png");
}
if (file_exists("auto.tag")) {
    self.ImportTags("auto.tag");
}

font_enable_effects(fnt_output, true, {
    outlineEnable: true,
    outlineDistance: 4,
    outlineColour: c_black,
    outlineAlpha: 1
});