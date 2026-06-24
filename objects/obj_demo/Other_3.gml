self.SaveTags("auto.txt");
self.ExportTags("auto.tag");
self.SaveImageMetadata(self.last_file_name, "auto");
if (sprite_exists(self.image)) {
    sprite_save(self.image, 0, "auto.png");
}