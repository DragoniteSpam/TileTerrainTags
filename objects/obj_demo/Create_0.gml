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

self.LoadImage = function(filename) {
    if (sprite_exists(self.image)) sprite_delete(self.image);
    self.image = sprite_add(filename, 0, false, false, 0, 0);
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
    }),
    new EmuText(c1, EMU_AUTO, ew, eh, "Tile size:"),
    new EmuInput(c1, EMU_AUTO, ew / 2, eh, "", string(self.cell_width), "tile width", 3, E_InputTypes.INT, function() {
        obj_demo.cell_width = real(self.value);
    })
        .SetInputBoxPosition(0, 0),
    new EmuInput(c1 + ew / 2, EMU_INLINE, ew / 2, eh, "", string(self.cell_width), "tile height", 3, E_InputTypes.INT, function() {
        obj_demo.cell_height= real(self.value);
    })
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
        self.drawCheckerbox(0, 0);
        matrix_set(matrix_world, matrix_build(-self.xoff, -self.yoff, 0, 0, 0, 0, self.zoom, self.zoom, 1));
        if (sprite_exists(obj_demo.image)) {
            draw_sprite(obj_demo.image, 0, 0, 0);
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