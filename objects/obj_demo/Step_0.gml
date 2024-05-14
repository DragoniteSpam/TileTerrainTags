var array = file_dropper_get_files([".png"]);
file_dropper_flush();

if (array_length(array) > 0) {
    self.LoadImage(array[0]);
}

if (keyboard_check(vk_control)) {
    if (keyboard_check(ord("C"))) {
        self.CopyCellMask();
    }
    if (keyboard_check(ord("V"))) {
        self.PasteCellMask();
    }
    if (keyboard_check(ord("N"))) {
        self.ResetCellMask();
    }
}