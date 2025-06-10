# 🖼️ Merge Images to PDF (Nemo Action)

This project provides three convenient [Nemo file manager](https://github.com/linuxmint/nemo) context menu actions to merge selected image files into a PDF. Designed for Linux Mint and other Nemo-powered environments, it supports both **default quick merge** and **interactive GUI configuration** modes.

## 📦 Features

- ✅ Right-click integration with Nemo
- 🖼️ Supports multiple image formats: PNG, JPEG, TIFF, BMP
- ⚙️ Two modes:
  - **Default Merge** – instant PDF with predefined settings
  - **Custom Merge (img2pdf GUI)** – interactive form to tweak layout, quality, orientation, DPI, and more
  - **Custom Merge (ImageMagik convert GUI)** – interactive form to tweak layout, quality, orientation, DPI, and more
- 🌐 Partially localized in 20+ languages
- 🧼 Temporary file cleanup
- 🧪 Smart defaults and user override support

## ⚡ Why Three Flavors?

To cover different use cases and balance between speed, file size, and compatibility, this project includes three merging strategies:

1. **Pure `img2pdf` mode** (default):
   - No recompression.
   - Maintains original image quality and resolution.
   - Extremely fast.
   - Great for already optimized images.

2. **Hybrid mode (`ImageMagick` + `img2pdf`)**:
   - Uses `convert` (ImageMagick) to resize or normalize images.
   - Passes the output to `img2pdf` to produce standards-compliant PDF/A.
   - Ideal for custom DPI, aspect ratio tweaks, or compressing oversized files.

3. **Classic ImageMagick-only (`convert`) mode**:
   - All-in-one: resizes and merges using just `convert`.
   - Compatible with legacy systems and complex format handling.
   - **⚠️ Note:** On modern Linux distributions, `convert` may **fail to produce PDF output** unless explicitly enabled. This is due to ImageMagick policy restrictions (e.g., disabling `PDF` delegates by default).
   - See:
     - 🧱 [Arch Wiki: ImageMagick – Security policy](https://wiki.archlinux.org/title/ImageMagick#Security_policy)
     - 📄 [ImageMagick: Enabling PDF write support](https://imagemagick.org/script/formats.php#ps)
     - 🔒 `/etc/ImageMagick-6/policy.xml` or `/etc/ImageMagick-7/policy.xml` may need to be modified to allow PDF write:
       ```xml
       <policy domain="coder" rights="read|write" pattern="PDF" />
       ```

For more on how `img2pdf` differs from traditional tools like `convert`, see:  
👉 [https://gitlab.mister-muffin.de/josch/img2pdf](https://gitlab.mister-muffin.de/josch/img2pdf)


## 🔧 Installation

1. Clone the repository:

    ```bash
    git clone https://github.com/kartun83/merge-img-pdf.git
    cd merge-img-pdf
    ```

2. Install dependencies:

    ```bash
    sudo apt install imagemagick img2pdf yad
    ```

3. Make the scripts executable:

    ```bash
    chmod +x img2pdf_default.sh img2pdf_gui.sh
    ```

4. Copy `.nemo_action` files to your local actions directory:

    ```bash
    mkdir -p ~/.local/share/nemo/actions
    cp actions/*.nemo_action ~/.local/share/nemo/actions/
    ```

5. Restart Nemo:

    ```bash
    nemo -q
    ```

## 🧠 Usage

- Select multiple images in your file manager.
- Right-click → **Merge to PDF (Default)** for an instant merge.
- Right-click → **Merge to PDF (img2pdf)** for GUI options.
- Right-click → **Merge to PDF (ImageMagik)** for GUI options.

## ⚙️ Notes

### Disabling Actions

If you don’t want some context menu options, you can disable one by editing its `.nemo_action` file:

```ini
[Nemo Action]
Active=false
```
Set Active=false in the corresponding .nemo_action file (merge-img-pdf-default@kartun83.nemo_action, merge-img-pdf-gui@kartun83.nemo_action, merge-pdf-gui@kartun83) to hide it from Nemo’s right-click menu.


### Debugging
To enable logging in img2pdf_gui.sh, set the LOGGING_ENABLED variable to true near the top of the script:
```bash
LOGGING_ENABLED="${LOGGING_ENABLED:-true}"
```

This will write debug output to:

```bash
LOG_FILE="$HOME/nemo_img2pdf.log"
```
Useful for diagnosing yad issues, argument expansion problems, and command failures.

## 🌍 Languages Supported

This tool comes partially translated in:

- English (default)
- Spanish (es)
- Portuguese (pt_BR)
- French (fr)
- German (de)
- Russian (ru)
- Ukrainian (uk)
- Italian (it)
- Dutch (nl)
- Polish (pl)
- Swedish (sv)
- Finnish (fi)
- Norwegian (nb)
- Turkish (tr)
- Czech (cs)
- Hungarian (hu)
- Romanian (ro)
- Japanese (ja)
- Korean (ko)
- Chinese (zh_CN)
- Arabic (ar)

Want to contribute a translation? Pull requests are welcome!

## 🧪 Development Notes

- The GUI uses `yad --form` and respects localization and dynamic value rendering.
- Scripts are written in POSIX-compliant `bash`.
- Localized strings use `gettext`, and translations are compiled from `.po` files.



## 📝 License

This project is licensed under the [MIT License](LICENSE).

## 🤝 Contributions

- Translations, bug fixes, and feature enhancements are welcome.
- Use [issues](https://github.com/kartun83/merge-img-pdf/issues) or [pull requests](https://github.com/kartun83/merge-img-pdf/pulls) to collaborate.

---
