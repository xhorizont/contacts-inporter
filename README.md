# Contacts Importer

Contacts Importer is a modern Flutter application that downloads an Outlook-compatible CSV file from a URL and merges the data with the contacts stored on a mobile device. Existing contacts are updated in place and new ones are created when needed, keeping the device phonebook in sync with the CSV source.

## Screens

- **Uvoz kontakov (Import)** – Accepts the CSV URL, displays contextual feedback (progress, success, or error banners), and shows a quick summary of processed contacts. Pressing **Posodobi** triggers the download, parsing, and merge procedure.
- **O aplikaciji (About)** – Presents a short informational paragraph. The view is intentionally minimal so the focus stays on the import workflow.

## Outlook CSV structure

Microsoft Outlook exports contact data with a predictable header layout. The importer understands the most common columns, including:

- `First Name`, `Middle Name`, `Last Name`, `Suffix`, `Title`
- `E-mail Address`, `E-mail 2 Address`, `E-mail 3 Address`
- `Mobile Phone`, `Home Phone`, `Home Phone 2`, `Business Phone`, `Business Phone 2`, `Company Main Phone`
- `Home Fax`, `Business Fax`, `Other Fax`, `Pager`, `Assistant Phone`, `Car Phone`
- `Company`, `Job Title`
- Address groups such as `Business Street`/`City`/`State`/`Postal Code`/`Country/Region` and their `Home`/`Other` counterparts
- `Notes`

> Tip: Exporting contacts from Outlook for Windows or web produces a CSV with these headers. Other tools that follow the same schema will also work.

## Permissions and platform notes

- **Android** – The app requests `INTERNET`, `READ_CONTACTS`, and `WRITE_CONTACTS` permissions and asks the user for runtime access before importing.
- **iOS & macOS** – `NSContactsUsageDescription` explains why contact access is required. Network requests should use HTTPS URLs to comply with App Transport Security policies.

## Running the project

1. Install the Flutter SDK (stable channel) and ensure `flutter doctor` reports no issues.
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application on a simulator or device:
   ```bash
   flutter run
   ```

## Example CSV snippet

```csv
First Name,Last Name,E-mail Address,Mobile Phone,Business Phone,Company,Job Title,Business Street,Business City,Business Country/Region,Notes
Ana,Novič,ana.novic@example.com,+38640111222,,Primer d.o.o.,Vodja prodaje,"Glavna ulica 12","Ljubljana","Slovenija","VIP stranka"
Boris,Kovač,boris.kovac@example.com,,+38614223344,Tehno d.d.,Inženir,"Industrijska cesta 8","Maribor","Slovenija","" 
```

The app parses every row, normalises email and phone values, and keeps a running summary of how many contacts were added, updated, or skipped.
