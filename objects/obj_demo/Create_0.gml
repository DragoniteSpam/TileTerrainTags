var ew = 320;
var eh = 32;
var spacing = 32;
var c1 = spacing;

self.tags = [
    "Solid",
    "Shallow Water",
    "Deep Water"
];

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
    self.container.GetChild("TAGS").ClearSelection();
};

self.container = new EmuCore(0, 0, room_width, room_height).AddContent([
    new EmuText(c1, EMU_AUTO, ew, eh, "[c_aqua]Tile Terrain Tags"),
    new EmuButton(c1, EMU_AUTO, ew, eh, "Load Image", function() {
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
    new EmuList(c1, EMU_AUTO, ew, eh, "Tags:", eh, 12, function() {
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
]);