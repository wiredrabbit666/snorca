# More filament brands in Snapmaker Orca

Out of the box, Snapmaker Orca only lets you pick **Generic**, **Polymaker** and **Snapmaker** filaments.
Regular OrcaSlicer has many more brands, such as Bambu, Elegoo, SUNLU, eSUN, Overture, COEX, Eolas Prints and Panchroma.

This patch makes the extra brands show up in Snapmaker Orca. Running it takes about a minute and needs no technical knowledge.

> Tested with **Snapmaker Orca 2.4.1** on **Windows**.

---

## How to install

1. **Download this project**
   On the GitHub page, click the green **Code** button, then **Download ZIP**.

2. **Unzip it**
   Right-click the downloaded ZIP file and choose **Extract All…**. The folder can go anywhere, for example your Desktop.

3. **Close Snapmaker Orca**
   Make sure it is completely closed. Check the taskbar.

4. **Run the patch**
   Open the unzipped folder and double-click **`Apply-Filament-Patch.bat`**.
   - Windows asks *"Do you want to allow this app to make changes?"*. Click **Yes**. The patch needs this to change files in `Program Files`.
   - If a blue **"Windows protected your PC"** box appears, click **More info**, then **Run anyway**.
   - A black window shows the progress and ends with **Done**. Press any key to close it.

5. **Choose your filaments**
   Start Snapmaker Orca and open the filament selection window (the one with the **System Filaments** and **Custom Filaments** tabs). In the **Vendor** row you'll now see the extra brands. Tick the filaments you want and click **Confirm**.

That's it.

---

## After a Snapmaker Orca update

Updating Snapmaker Orca puts its original files back, so the extra brands disappear again.
To get them back, run **`Apply-Filament-Patch.bat`** again after each update. Running it more than once does no harm.

## How to remove it

Close Snapmaker Orca and double-click **`Undo-Filament-Patch.bat`**. All original files are put back exactly as they were.
Reinstalling Snapmaker Orca also removes the patch.

---

## Good to know

- **RFID:** the printer's RFID reader only recognises Snapmaker filaments. For other brands, choose the filament by hand in the slicer.
- **The profiles come from OrcaSlicer** and are general-purpose. They aren't tuned for the U1, so print a test piece and adjust temperatures and flow if needed.
- **"ERROR: … does not look like the expected file"** means a newer Snapmaker Orca changed the files this patch edits. Nothing was changed. Please open an issue on GitHub.
- **"ERROR: Snapmaker Orca is running"**: close it completely and try again.
- **Installed somewhere other than `C:\Program Files\Snapmaker_Orca`?** The patch looks up the install location automatically. If it still can't find it, open PowerShell as administrator in the unzipped folder and run:
  `powershell -ExecutionPolicy Bypass -File install_patch\filament-patch.ps1 -InstallDir "D:\Your\Snapmaker_Orca"`

---

## For the technically curious

Snapmaker Orca hides the extra brands in two places:

1. `resources\profiles\OrcaFilamentLibrary.json` ships with an **empty filament list**. The filament selection dialog only shows what this list names.
2. The dialog's scripts, `resources\web\guide\22\22.js` (setup wizard) and `23\23.js` (filament selection), have the line that shows filaments without a fixed printer list **commented out**. Snapmaker's commit message for this was "Hide system filament". Library filaments work with every printer, so they don't have such a list.

On every start, Snapmaker Orca copies the library from its install folder into `%APPDATA%\Snapmaker_Orca\system`. Editing the AppData copy therefore doesn't last, and the patch has to change the install folder.

What `install_patch\filament-patch.ps1` does:

- Backs up the original files to `<install>\filament_patch_backup`, which Undo uses.
- Un-comments `bFind=true;` in both dialog scripts. It stops without changing anything if the files don't match what it expects.
- Copies in the filament profile files that are missing. Snapmaker's own versions of existing files are kept.
- Installs the filled-in `OrcaFilamentLibrary.json`, with 482 entries taken from OrcaSlicer 2.4.3. It first checks that every file in the list exists.

Repository layout:

| Path | Contents |
|---|---|
| `Apply-Filament-Patch.bat` / `Undo-Filament-Patch.bat` | Double-click launchers. They ask for admin rights and run the script. |
| `install_patch/filament-patch.ps1` | The patch script |
| `install_patch/files/` | The filament list and profile files to install |
| `install_patch/original/` | Unmodified Snapmaker Orca 2.4.1 files, for reference |
| `system/` | The maintainer's own Snapmaker Orca settings folder (`%APPDATA%\Snapmaker_Orca`), tracked to record customisations. Not needed to install the patch. |
