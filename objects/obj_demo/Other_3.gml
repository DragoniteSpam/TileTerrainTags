self.SaveTags("auto.txt");
self.ExportTags("auto.tag");
if (sprite_exists(self.image)) {
    sprite_save(self.image, 0, "auto.png");
}