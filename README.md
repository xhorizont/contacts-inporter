# Contacts Importer

A simple and modern mobile application built with Flutter for importing contacts from a CSV file.

## Features

- Minimalist and modern UI
- Two main screens:
	- **Import Screen:** Enter a URL to a CSV file, press "Update", and the app fetches, reads, and imports contacts into the phone. If a contact already exists and has changed, it will be merged. Displays "Transfer complete" when done.
	- **About Screen:** Contains a short description of the app.
- Handles Android permissions for contacts and internet access.

## Usage

1. Enter the URL of a CSV file containing contacts in the input field.
2. Tap the "Update" button.
3. The app will download the CSV, read the contacts, and import or update them on your device.
4. When finished, a message "Transfer complete" will be shown.

## About

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed euismod, urna eu tincidunt consectetur, nisi nisl aliquam nunc, eget aliquam massa nisl quis neque.

## CSV File Structure (MS Outlook Example)

The CSV file should follow the standard format exported by MS Outlook. Typical columns include:

- First Name
- Last Name
- E-mail Address
- Mobile Phone
- Home Phone
- Business Phone
- Company
- Job Title
- Address
- Notes

Example:

```
First Name,Last Name,E-mail Address,Mobile Phone,Home Phone,Business Phone,Company,Job Title,Address,Notes
John,Doe,john.doe@email.com,123456789,,987654321,Acme Corp,Manager,"123 Main St, City",""
Jane,Smith,jane.smith@email.com,234567890,345678901,,Widgets Inc,Developer,"456 Elm St, City","VIP"
```

> For best results, export your contacts from MS Outlook as a CSV and use that file with this app.
# contacts-inporter