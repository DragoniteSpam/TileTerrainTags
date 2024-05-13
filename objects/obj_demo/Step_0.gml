var array = file_dropper_get_files([".png"]);
file_dropper_flush();

if (array_length(array) > 0) {
    self.LoadImage(array[0]);
}