# E.V. LIBRARY – Multi-Sheet Edition

This Flutter app can connect to any Google Spreadsheet that follows the required Books-sheet structure.

## Required Books columns
Stock Number, Call Number, Title, Author, Language, Category, Price, Publisher, Edition, Shelf, Barcode, Book Type, Status, Subjects.

## Setup
1. Deploy the supplied Apps Script backend as a Web App.
2. Give the Apps Script account access to every spreadsheet you want to use.
3. Open **Settings** in the app.
4. Enter the Apps Script Web App URL.
5. Enter either the full Google Sheet URL or the Spreadsheet ID.
6. Tap **Test Sheet**. The app checks the Books sheet headers before saving the connection.

The selected spreadsheet is stored locally on the device. All add/search/update/configuration requests are sent to that selected spreadsheet.

If a selected spreadsheet does not yet contain configuration sheets (Categories, Languages, Shelves, BookTypes, Statuses), the backend can create them with defaults when configuration is requested.

## Optional fields
- Status is optional when adding a book and may be left blank.
- Subjects is optional when adding a book and may be left blank.
- Blank values are stored as blank cells in the Books sheet.


## E.V.Library preconfigured connection
The source is preconfigured for the current Apps Script Web App and E.V.Library spreadsheet:
- Web App: https://script.google.com/macros/s/AKfycbz7Va0uQdA5KJwIObSEX5Hbt0Ff9fTYgQm8GmyBhy7bS3ioyd72jPXkrPae-4Uirfbw/exec
- Spreadsheet ID: 1dEVzYCCZPvOCuq45EYXMkkFiKpmcfFkGm7m8jXtwM00

The app still keeps these values editable in Settings.
