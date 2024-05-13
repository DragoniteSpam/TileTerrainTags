var ew = 320;
var eh = 32;
var spacing = 32;
var c1 = spacing;
var c2 = c1 + ew + spacing;

self.tags = [
    "Solid",
    "Shallow Water",
    "Deep Water"
];

self.image = undefined;
self.cell_width = 32;
self.cell_height = 32;
self.cell = -1;
self.cell_values = [];

self.SelectCell = function(x, y) {
    if (!sprite_exists(self.image)) return;
    self.cell = x + y * (sprite_get_width(self.image) div self.cell_width);
};

self.GetCellIndex = function(x, y) {
    return x + y * (sprite_get_width(self.image) div self.cell_width);
};

self.GetCellValue = function(x, y) {
    return self.cell_values[x + y * (sprite_get_width(self.image) div self.cell_width)];
};

self.SetCellValue = function(x, y, value) {
    self.cell_values[x + y * (sprite_get_width(self.image) div self.cell_width)] = value;
};

self.LoadImage = function(filename) {
    if (sprite_exists(self.image)) sprite_delete(self.image);
    self.image = sprite_add(filename, 0, false, false, 0, 0);
    self.cell = -1;
    self.ResetCellData();
};

self.ResetCellData = function() {
    self.cell_values = array_create((sprite_get_width(self.image) div self.cell_width) * (sprite_get_height(self.image) div self.cell_height), 0);
};

self.ExportTags = function(filename) {
    var buffer = buffer_create(1000, buffer_grow, 1);
    array_foreach(self.cell_values, method({ buffer }, function(tag) {
        buffer_write(self.buffer, buffer_u64, tag);
    }));
    buffer_save_ext(buffer, filename, 0, buffer_tell(buffer));
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
    self.tags = string_split(buffer_read(buffer, buffer_text), "\n");
    array_map_ext(self.tags, function(item) {
        return string_trim(item);
    });
    buffer_delete(buffer);
    self.container.GetChild("TAGS").SetList(self.tags);
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
            self.SaveTags(filename);
        }
    }),
    new EmuButton(c1, EMU_AUTO, ew, eh, "Load Tags", function() {
        var filename = get_save_filename("Text files|*.txt", "tags.txt");
        if (file_exists(filename)) {
            self.LoadTags(filename);
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
        self.ResetCellData();
    })
        .SetRequireConfirm(true)
        .SetInputBoxPosition(0, 0),
    new EmuInput(c1 + ew / 2, EMU_INLINE, ew / 2, eh, "", string(self.cell_width), "tile height", 3, E_InputTypes.INT, function() {
        obj_demo.cell_height= real(self.value);
        self.ResetCellData();
    })
        .SetRequireConfirm(true)
        .SetInputBoxPosition(0, 0),
    new EmuList(c1, EMU_AUTO, ew, eh, "Tags:", eh, 10, function() {
        var selection = self.GetSelection();
        if (selection != -1) {
            self.GetSibling("NAME").SetValue(obj_demo.tags[selection]);
        }
    })
        .SetList(self.tags)
        .SetID("TAGS"),
    new EmuButton(c1, EMU_AUTO, ew, eh, "Add Tag", function() {
        array_push(obj_demo.tags, $"Tag{array_length(obj_demo.tags)}");
        if (self.GetSibling("TAGS").GetSelection() == -1) {
            self.GetSibling("TAGS").Select(array_length(obj_demo.tags) - 1);
        }
    })
        .SetUpdate(function() {
            self.SetInteractive(array_length(obj_demo.tags) < 62);
        }),
    new EmuButton(c1, EMU_AUTO, ew, eh, "Delete Tag", function() {
        var tag_list = self.GetSibling("TAGS");
        var selection = tag_list.GetSelection();
        array_delete(obj_demo.tags, selection, 1);
        if (selection < array_length(obj_demo.tags)) {
            tag_list.Select(selection);
        } else {
            tag_list.ClearSelection();
        }
    })
        .SetUpdate(function() {
            var has_selection = self.GetSibling("TAGS").GetSelection() != -1;
            self.SetInteractive(array_length(obj_demo.tags) > 0 && has_selection);
        }),
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
            
            // deal with the highlighted cell
            mx += self.xoff;
            my += self.yoff;
            mx /= self.zoom;
            my /= self.zoom;
            
            var xc = mx div w;
            var yc = my div h;
            
            if (xc >= 0 && yc >= 0 && xc < hc && yc < vc) {
                if (mouse_check_button_pressed(mb_left)) {
                    obj_demo.SelectCell(xc, yc);
                }
                
                var x1 = xc * w;
                var y1 = yc * h;
                
                draw_sprite_ext(spr_highlight, 0, x1, y1, 1, 1, 0, c_green, 1);
            }
            
            // draw the currently-selected cell
            if (obj_demo.cell != -1) {
                xc = obj_demo.cell mod hc;
                yc = obj_demo.cell div hc;
                var x1 = xc * w;
                var y1 = yc * h;
                
                draw_sprite_ext(spr_highlight, 0, x1, y1, 1, 1, 0, c_blue, 1);
            }
            
            static text_color = c_white;
            static text_scale = 1 / 4;
            static text_alpha = 0.4;
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_font(fnt_output);
            
            // draw the readouts
            for (var i = 0; i < hc; i++) {
                for (var j = 0; j < vc; j++) {
                    var xx = i * w + w / 2;
                    var yy = j * h + h / 2;
                    draw_text_transformed_color(xx, yy, obj_demo.Hexify(obj_demo.GetCellValue(i, j)), text_scale, text_scale, 0, text_color, text_color, text_color, text_color, text_alpha);
                }
            }
        }
        
        matrix_set(matrix_world, matrix_build_identity());
    }, function(mx, my) {
        // step
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
    })
]);

if (file_exists("auto.txt")) {
    self.LoadTags("auto.txt");
}
if (file_exists("auto.png")) {
    self.LoadImage("auto.png");
}

font_enable_effects(fnt_output, true, {
    outlineEnable: true,
    outlineDistance: 4,
    outlineColour: c_black,
    outlineAlpha: 1
});