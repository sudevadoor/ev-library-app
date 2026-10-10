/************************************************************
 * EV LIBRARY - COMPLETE UPDATED GOOGLE APPS SCRIPT BACKEND
 * Version: 2026-10
 *
 * Replace the COMPLETE contents of code.gs with this file.
 *
 * Google Spreadsheet:
 * 1dEVzYCCZPvOCuq45EYXMkkFiKpmcfFkGm7m8jXtwM00
 *
 * IMPORTANT DEPLOYMENT SETTINGS:
 *   Execute as: Me
 *   Who has access: Anyone
 *
 * Main sheet:
 *   Books
 *
 * Configuration sheets:
 *   Shelves
 *   Categories
 *   Languages
 *   BookTypes
 *   Statuses
 *
 * BOOK ENTRY:
 * - Manual entry is supported for every Books field.
 * - OCR is performed by the Flutter app; this backend simply
 *   accepts the resulting values.
 * - Barcode/ISBN scanning is handled by the Flutter app.
 * - ISBN metadata lookup is available through Google Books.
 * - Call Number is generated here and remains editable in app.
 *
 * SHELF MANAGEMENT:
 * - All shelves are stored in the Shelves sheet.
 * - The app can display 8 at a time.
 * - This backend supports paged shelf retrieval.
 * - Shelves can be added, edited, deleted, or replaced.
 * - Changing the shelf list does NOT change existing Books rows.
 ************************************************************/

var DEFAULT_SHEET_ID =
  "1dEVzYCCZPvOCuq45EYXMkkFiKpmcfFkGm7m8jXtwM00";

var BOOKS_SHEET_NAME = "Books";
var LEGACY_BOOKS_SHEET_NAME = "Form Responses 1";
var SHELVES_SHEET_NAME = "Shelves";
var CATEGORIES_SHEET_NAME = "Categories";
var LANGUAGES_SHEET_NAME = "Languages";
var BOOK_TYPES_SHEET_NAME = "BookTypes";
var STATUSES_SHEET_NAME = "Statuses";

var REQUIRED_COLUMNS = [
  "Stock Number",
  "Call Number",
  "Title",
  "Author",
  "Language",
  "Category",
  "Price",
  "Publisher",
  "Edition",
  "Shelf",
  "Barcode",
  "Book Type",
  "Status",
  "Subjects"
];

var DEFAULT_CATEGORIES = [
  "Novel",
  "Stories",
  "Essays",
  "Drama",
  "Biography",
  "Poems",
  "Travelogue",
  "Balasahithyam",
  "History"
];

var DEFAULT_LANGUAGES = [
  "Malayalam",
  "English",
  "Hindi",
  "Tamil",
  "Kannada",
  "Other"
];

var DEFAULT_BOOK_TYPES = [
  "Text Book",
  "Reference",
  "General",
  "Novel",
  "Magazine",
  "Other"
];

var DEFAULT_STATUSES = [
  "Available",
  "Issued",
  "Lost",
  "Damaged",
  "Withdrawn"
];

/* ==========================================================
   WEB APP
   ========================================================== */

function doGet(e) {
  try {
    var ss = openSpreadsheet(DEFAULT_SHEET_ID);

    return json({
      success: true,
      message: "EV Library Backend is working.",
      spreadsheet: ss.getName(),
      sheets: getSheetNames_(ss),
      version: "EV-LIBRARY-MULTISHEET-2026-10"
    });

  } catch (error) {
    return json({
      success: false,
      error: errorMessage_(error)
    });
  }
}

function doPost(e) {
  try {
    var request = parseRequest_(e);
    var action = stringValue_(request.action);

    /* ---------- System ---------- */

    if (action === "validateSheet") {
      return json(
        validateSheet(
          request.sheetUrl || request.sheetId
        )
      );
    }

    if (action === "testBackend") {
      return json(testLibraryBackend(request.sheetId));
    }

    if (action === "initializeLibraryConfig") {
      return json(initializeLibraryConfig(request.sheetId));
    }

    /* ---------- Configuration ---------- */

    if (action === "getConfig") {
      return json(getConfig(request.sheetId));
    }

    if (action === "saveCategories") {
      return json(saveSimpleList(
        request.sheetId,
        CATEGORIES_SHEET_NAME,
        request.categories || [],
        "Category"
      ));
    }

    if (action === "saveLanguages") {
      return json(saveSimpleList(
        request.sheetId,
        LANGUAGES_SHEET_NAME,
        request.languages || [],
        "Language"
      ));
    }

    if (action === "saveStatuses") {
      return json(saveSimpleList(
        request.sheetId,
        STATUSES_SHEET_NAME,
        request.statuses || [],
        "Status"
      ));
    }

    if (action === "saveBookTypes") {
      return json(saveSimpleList(
        request.sheetId,
        BOOK_TYPES_SHEET_NAME,
        request.bookTypes || [],
        "Book Type"
      ));
    }

    /* ---------- Shelves ---------- */

    if (action === "getShelves") {
      return json(
        getShelves(
          request.sheetId,
          request.page,
          request.pageSize
        )
      );
    }

    if (action === "getShelvesPage") {
      return json(
        getShelves(
          request.sheetId,
          request.page,
          request.pageSize
        )
      );
    }

    if (action === "saveShelves") {
      return json(
        saveShelves(
          request.sheetId,
          request.shelves || []
        )
      );
    }

    if (action === "addShelf") {
      return json(
        addShelf(
          request.sheetId,
          request.shelf
        )
      );
    }

    if (action === "updateShelf") {
      return json(
        updateShelf(
          request.sheetId,
          request.oldShelf,
          request.newShelf
        )
      );
    }

    if (action === "deleteShelf") {
      return json(
        deleteShelf(
          request.sheetId,
          request.shelf
        )
      );
    }

    if (action === "checkShelf") {
      return json(
        checkShelf(
          request.sheetId,
          request.shelf
        )
      );
    }

    /* ---------- Barcode / ISBN ---------- */

    if (action === "checkBarcode") {
      return json(
        checkBarcode(
          request.sheetId,
          request.barcode
        )
      );
    }

    if (action === "getBookByBarcode") {
      return json(
        getBookByBarcode(
          request.sheetId,
          request.barcode
        )
      );
    }

    if (
      action === "getBookMetadata" ||
      action === "lookupISBN"
    ) {
      return json(
        getBookMetadata(
          request.barcode || request.isbn
        )
      );
    }

    /* ---------- Stock ---------- */

    if (action === "checkStockNumber") {
      return json(
        checkStockNumber(
          request.sheetId,
          request.stockNumber
        )
      );
    }

    if (action === "getNextStockNumber") {
      return json(
        getNextStockNumber(
          request.sheetId
        )
      );
    }

    /* ---------- Books ---------- */

    if (action === "addBook") {
      return json(
        addBook(
          request.sheetId,
          request.book || {},
          request.allowDuplicateBarcode === true
        )
      );
    }

    if (action === "updateBook") {
      return json(
        updateBook(
          request.sheetId,
          request.stockNumber,
          request.book || {}
        )
      );
    }

    if (action === "getBook") {
      return json(
        getBook(
          request.sheetId,
          request.stockNumber
        )
      );
    }

    if (action === "searchBooks") {
      return json(
        searchBooks(
          request.sheetId,
          request.query
        )
      );
    }

    /* ---------- Call Number ---------- */

    if (action === "generateCallNumber") {
      return json(
        generateCallNumber(
          request.sheetId,
          request.book || {}
        )
      );
    }

    return json({
      success: false,
      error: "Unknown action: " + action
    });

  } catch (error) {
    return json({
      success: false,
      error: errorMessage_(error)
    });
  }
}

/* ==========================================================
   REQUEST / RESPONSE HELPERS
   ========================================================== */

function parseRequest_(e) {
  if (
    e &&
    e.postData &&
    e.postData.contents
  ) {
    var raw =
      String(e.postData.contents).trim();

    if (raw !== "") {
      try {
        return JSON.parse(raw);
      } catch (ignore) {
        /* Try form parameters below. */
      }
    }
  }

  if (e && e.parameter) {
    var result = {};
    var keys =
      Object.keys(e.parameter);

    for (
      var i = 0;
      i < keys.length;
      i++
    ) {
      var key = keys[i];
      var value = e.parameter[key];

      if (typeof value === "string") {
        var trimmed =
          value.trim();

        if (
          trimmed.indexOf("{") === 0 ||
          trimmed.indexOf("[") === 0
        ) {
          try {
            value = JSON.parse(value);
          } catch (ignore2) {}
        }
      }

      result[key] = value;
    }

    return result;
  }

  throw new Error(
    "No request data received."
  );
}

function json(data) {
  return ContentService
    .createTextOutput(
      JSON.stringify(data)
    )
    .setMimeType(
      ContentService.MimeType.JSON
    );
}

function errorMessage_(error) {
  if (
    error &&
    error.message
  ) {
    return String(
      error.message
    );
  }

  return String(error);
}

function stringValue_(value) {
  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }

  return String(value).trim();
}

function normalizeBarcode_(value) {
  return stringValue_(value)
    .replace(/[\s-]/g, "");
}

function toInteger_(value, fallback) {
  var number =
    parseInt(
      value,
      10
    );

  if (
    isNaN(number) ||
    number < 0
  ) {
    return fallback;
  }

  return number;
}

/* ==========================================================
   SPREADSHEET HELPERS
   ========================================================== */

function extractSheetId_(value) {
  var text =
    stringValue_(value);

  if (text === "") {
    return "";
  }

  var match =
    text.match(
      /spreadsheets\/d\/([a-zA-Z0-9-_]+)/
    );

  if (match) {
    return match[1];
  }

  return text;
}

function openSpreadsheet(sheetId) {
  var id =
    extractSheetId_(
      sheetId || DEFAULT_SHEET_ID
    );

  if (id === "") {
    throw new Error(
      "Google Sheet ID is empty."
    );
  }

  return SpreadsheetApp.openById(
    id
  );
}

function findExistingBooksSheet_(ss) {
  var sheet = ss.getSheetByName(BOOKS_SHEET_NAME);
  if (sheet) return sheet;

  // The current E.V.Library spreadsheet stores the book stock in
  // "Form Responses 1". Reuse it rather than creating a new Books sheet.
  var legacy = ss.getSheetByName(LEGACY_BOOKS_SHEET_NAME);
  if (legacy) return legacy;

  return null;
}

function getBooksSheet(sheetId) {
  var ss = openSpreadsheet(sheetId);
  var sheet = findExistingBooksSheet_(ss);

  if (!sheet) {
    sheet = ss.insertSheet(BOOKS_SHEET_NAME);
  }

  ensureBooksHeaders_(sheet);
  return sheet;
}

function getSheetNames_(ss) {
  var sheets =
    ss.getSheets();

  var names = [];

  for (
    var i = 0;
    i < sheets.length;
    i++
  ) {
    names.push(
      sheets[i].getName()
    );
  }

  return names;
}

function ensureBooksHeaders_(sheet) {
  var lastColumn =
    sheet.getLastColumn();

  if (
    sheet.getLastRow() === 0 ||
    lastColumn === 0
  ) {
    sheet
      .getRange(
        1,
        1,
        1,
        REQUIRED_COLUMNS.length
      )
      .setValues([
        REQUIRED_COLUMNS
      ]);

    return;
  }

  var width =
    Math.max(
      lastColumn,
      REQUIRED_COLUMNS.length
    );

  var headers =
    sheet
      .getRange(
        1,
        1,
        1,
        width
      )
      .getDisplayValues()[0];

  var existing = [];
  var hasHeader = false;

  for (
    var i = 0;
    i < headers.length;
    i++
  ) {
    existing.push(
      stringValue_(
        headers[i]
      )
    );

    if (
      stringValue_(
        headers[i]
      ) !== ""
    ) {
      hasHeader = true;
    }
  }

  if (!hasHeader) {
    sheet
      .getRange(
        1,
        1,
        1,
        REQUIRED_COLUMNS.length
      )
      .setValues([
        REQUIRED_COLUMNS
      ]);

    return;
  }

  for (
    var c = 0;
    c < REQUIRED_COLUMNS.length;
    c++
  ) {
    var required =
      REQUIRED_COLUMNS[c];

    if (
      existing.indexOf(
        required
      ) === -1
    ) {
      var emptyIndex =
        existing.indexOf("");

      if (
        emptyIndex === -1
      ) {
        sheet.insertColumnAfter(
          existing.length
        );

        existing.push("");
        emptyIndex =
          existing.length - 1;
      }

      sheet
        .getRange(
          1,
          emptyIndex + 1
        )
        .setValue(
          required
        );

      existing[emptyIndex] =
        required;
    }
  }
}

function getHeaderMap_(sheet) {
  ensureBooksHeaders_(
    sheet
  );

  var headers =
    sheet
      .getRange(
        1,
        1,
        1,
        sheet.getLastColumn()
      )
      .getDisplayValues()[0];

  var map = {};

  for (
    var i = 0;
    i < headers.length;
    i++
  ) {
    var name =
      stringValue_(
        headers[i]
      );

    if (name !== "") {
      map[name] = i;
    }
  }

  return map;
}

function rowToBook_(
  row,
  map
) {
  var book = {};
  var keys =
    Object.keys(map);

  for (
    var i = 0;
    i < keys.length;
    i++
  ) {
    var key = keys[i];
    var index = map[key];

    book[key] =
      row[index] === null ||
      row[index] === undefined
        ? ""
        : String(row[index]);
  }

  return book;
}

function bookToRow_(
  book,
  map,
  existingRow
) {
  var width =
    Object.keys(map).length;

  var row;

  if (existingRow) {
    row =
      existingRow.slice();
  } else {
    row = [];

    for (
      var i = 0;
      i < width;
      i++
    ) {
      row.push("");
    }
  }

  var keys =
    Object.keys(map);

  for (
    var j = 0;
    j < keys.length;
    j++
  ) {
    var key = keys[j];

    if (
      Object.prototype.hasOwnProperty.call(
        book,
        key
      )
    ) {
      row[map[key]] =
        book[key] === null ||
        book[key] === undefined
          ? ""
          : book[key];
    }
  }

  return row;
}

function unique_(items) {
  var seen = {};
  var output = [];

  for (
    var i = 0;
    i < items.length;
    i++
  ) {
    var value =
      stringValue_(
        items[i]
      );

    if (value === "") {
      continue;
    }

    var key =
      value.toLowerCase();

    if (!seen[key]) {
      seen[key] = true;
      output.push(value);
    }
  }

  return output;
}

/* ==========================================================
   CONFIGURATION
   ========================================================== */

function getSimpleList_(
  ss,
  sheetName,
  header,
  defaults
) {
  var sheet =
    ss.getSheetByName(
      sheetName
    );

  if (!sheet) {
    sheet =
      ss.insertSheet(
        sheetName
      );

    sheet
      .getRange(1, 1)
      .setValue(header);

    if (
      defaults.length > 0
    ) {
      var defaultRows = [];

      for (
        var i = 0;
        i < defaults.length;
        i++
      ) {
        defaultRows.push([
          defaults[i]
        ]);
      }

      sheet
        .getRange(
          2,
          1,
          defaultRows.length,
          1
        )
        .setValues(
          defaultRows
        );
    }

    return defaults.slice();
  }

  if (
    sheet.getLastRow() < 2
  ) {
    return defaults.slice();
  }

  var values =
    sheet
      .getRange(
        2,
        1,
        sheet.getLastRow() - 1,
        1
      )
      .getDisplayValues();

  var list = [];

  for (
    var j = 0;
    j < values.length;
    j++
  ) {
    var value =
      stringValue_(
        values[j][0]
      );

    if (value !== "") {
      list.push(value);
    }
  }

  if (list.length === 0) {
    return defaults.slice();
  }

  return unique_(list);
}

function getShelves_(
  ss
) {
  var sheet =
    ss.getSheetByName(
      SHELVES_SHEET_NAME
    );

  if (!sheet) {
    sheet =
      ss.insertSheet(
        SHELVES_SHEET_NAME
      );

    sheet
      .getRange(1, 1)
      .setValue("Shelf");

    return [];
  }

  if (
    sheet.getLastRow() < 2
  ) {
    return [];
  }

  var values =
    sheet
      .getRange(
        2,
        1,
        sheet.getLastRow() - 1,
        1
      )
      .getDisplayValues();

  var list = [];

  for (
    var i = 0;
    i < values.length;
    i++
  ) {
    var value =
      stringValue_(
        values[i][0]
      );

    if (value !== "") {
      list.push(value);
    }
  }

  return unique_(list);
}

function getConfig(
  sheetId
) {
  var ss =
    openSpreadsheet(
      sheetId
    );

  return {
    success: true,

    categories:
      getSimpleList_(
        ss,
        CATEGORIES_SHEET_NAME,
        "Category",
        DEFAULT_CATEGORIES
      ),

    languages:
      getSimpleList_(
        ss,
        LANGUAGES_SHEET_NAME,
        "Language",
        DEFAULT_LANGUAGES
      ),

    shelves:
      getShelves_(
        ss
      ),

    bookTypes:
      getSimpleList_(
        ss,
        BOOK_TYPES_SHEET_NAME,
        "Book Type",
        DEFAULT_BOOK_TYPES
      ),

    statuses:
      getSimpleList_(
        ss,
        STATUSES_SHEET_NAME,
        "Status",
        DEFAULT_STATUSES
      )
  };
}

function saveSimpleList(
  sheetId,
  sheetName,
  values,
  header
) {
  var ss =
    openSpreadsheet(
      sheetId
    );

  var sheet =
    ss.getSheetByName(
      sheetName
    );

  if (!sheet) {
    sheet =
      ss.insertSheet(
        sheetName
      );
  }

  var cleaned =
    unique_(
      values || []
    );

  sheet.clearContents();

  sheet
    .getRange(1, 1)
    .setValue(header);

  if (
    cleaned.length > 0
  ) {
    var rows = [];

    for (
      var i = 0;
      i < cleaned.length;
      i++
    ) {
      rows.push([
        cleaned[i]
      ]);
    }

    sheet
      .getRange(
        2,
        1,
        rows.length,
        1
      )
      .setValues(rows);
  }

  return {
    success: true,
    count: cleaned.length
  };
}

function initializeLibraryConfig(sheetId) {
  var targetSheetId = sheetId || DEFAULT_SHEET_ID;
  var ss =
    openSpreadsheet(
      targetSheetId
    );

  getSimpleList_(
    ss,
    CATEGORIES_SHEET_NAME,
    "Category",
    DEFAULT_CATEGORIES
  );

  getSimpleList_(
    ss,
    LANGUAGES_SHEET_NAME,
    "Language",
    DEFAULT_LANGUAGES
  );

  getShelves_(
    ss
  );

  getSimpleList_(
    ss,
    BOOK_TYPES_SHEET_NAME,
    "Book Type",
    DEFAULT_BOOK_TYPES
  );

  getSimpleList_(
    ss,
    STATUSES_SHEET_NAME,
    "Status",
    DEFAULT_STATUSES
  );

  return {
    success: true,
    message:
      "Configuration sheets are ready.",
    sheets:
      getSheetNames_(ss)
  };
}

/* ==========================================================
   SHELF MANAGEMENT
   ========================================================== */

/*
 * Returns shelves in pages.
 *
 * Default:
 *   page = 0
 *   pageSize = 8
 *
 * Example:
 *   page 0 -> shelves 1-8
 *   page 1 -> shelves 9-16
 */
function getShelves(
  sheetId,
  page,
  pageSize
) {
  var all =
    getShelves_(
      openSpreadsheet(sheetId)
    );

  var currentPage =
    toInteger_(
      page,
      0
    );

  var size =
    toInteger_(
      pageSize,
      8
    );

  if (size < 1) {
    size = 8;
  }

  if (size > 100) {
    size = 100;
  }

  var start =
    currentPage * size;

  if (
    start >= all.length &&
    all.length > 0
  ) {
    currentPage =
      Math.floor(
        (all.length - 1) /
        size
      );

    start =
      currentPage * size;
  }

  var pageItems =
    all.slice(
      start,
      start + size
    );

  var totalPages =
    all.length === 0
      ? 0
      : Math.ceil(
          all.length / size
        );

  return {
    success: true,
    shelves: pageItems,
    allShelves: all,
    page: currentPage,
    pageSize: size,
    totalShelves: all.length,
    totalPages: totalPages,
    hasPrevious:
      currentPage > 0,
    hasNext:
      start + size < all.length
  };
}

function checkShelf(
  sheetId,
  shelf
) {
  var value =
    stringValue_(shelf);

  if (value === "") {
    return {
      success: false,
      exists: false,
      error:
        "Shelf number is empty."
    };
  }

  var all =
    getShelves_(
      openSpreadsheet(sheetId)
    );

  for (
    var i = 0;
    i < all.length;
    i++
  ) {
    if (
      all[i].toLowerCase() ===
      value.toLowerCase()
    ) {
      return {
        success: true,
        exists: true,
        shelf: all[i],
        index: i
      };
    }
  }

  return {
    success: true,
    exists: false,
    shelf: value
  };
}

function saveShelves(
  sheetId,
  shelves
) {
  var cleaned =
    unique_(
      shelves || []
    );

  return saveSimpleList(
    sheetId,
    SHELVES_SHEET_NAME,
    cleaned,
    "Shelf"
  );
}

function addShelf(
  sheetId,
  shelf
) {
  var value =
    stringValue_(shelf);

  if (value === "") {
    return {
      success: false,
      error:
        "Shelf number is empty."
    };
  }

  var lock =
    LockService.getScriptLock();

  lock.waitLock(15000);

  try {
    var ss =
      openSpreadsheet(
        sheetId
      );

    var all =
      getShelves_(ss);

    for (
      var i = 0;
      i < all.length;
      i++
    ) {
      if (
        all[i].toLowerCase() ===
        value.toLowerCase()
      ) {
        return {
          success: false,
          exists: true,
          error:
            "Shelf already exists: " +
            all[i]
        };
      }
    }

    all.push(value);

    return saveShelves(
      sheetId,
      all
    );

  } finally {
    lock.releaseLock();
  }
}

function updateShelf(
  sheetId,
  oldShelf,
  newShelf
) {
  var oldValue =
    stringValue_(oldShelf);

  var newValue =
    stringValue_(newShelf);

  if (
    oldValue === "" ||
    newValue === ""
  ) {
    return {
      success: false,
      error:
        "Both old and new shelf numbers are required."
    };
  }

  var lock =
    LockService.getScriptLock();

  lock.waitLock(15000);

  try {
    var ss =
      openSpreadsheet(
        sheetId
      );

    var all =
      getShelves_(ss);

    var foundIndex = -1;

    for (
      var i = 0;
      i < all.length;
      i++
    ) {
      if (
        all[i].toLowerCase() ===
        oldValue.toLowerCase()
      ) {
        foundIndex = i;
        break;
      }
    }

    if (foundIndex === -1) {
      return {
        success: false,
        error:
          "Shelf not found: " +
          oldValue
      };
    }

    for (
      var j = 0;
      j < all.length;
      j++
    ) {
      if (
        j !== foundIndex &&
        all[j].toLowerCase() ===
        newValue.toLowerCase()
      ) {
        return {
          success: false,
          error:
            "New shelf number already exists: " +
            all[j]
        };
      }
    }

    all[foundIndex] =
      newValue;

    /*
     * IMPORTANT:
     * Existing Books rows are NOT modified.
     * Only the shelf configuration list changes.
     */
    var result =
      saveShelves(
        sheetId,
        all
      );

    result.oldShelf =
      oldValue;
    result.newShelf =
      newValue;

    return result;

  } finally {
    lock.releaseLock();
  }
}

function deleteShelf(
  sheetId,
  shelf
) {
  var value =
    stringValue_(shelf);

  if (value === "") {
    return {
      success: false,
      error:
        "Shelf number is required."
    };
  }

  var lock =
    LockService.getScriptLock();

  lock.waitLock(15000);

  try {
    var ss =
      openSpreadsheet(
        sheetId
      );

    var all =
      getShelves_(ss);

    var found = false;
    var remaining = [];

    for (
      var i = 0;
      i < all.length;
      i++
    ) {
      if (
        all[i].toLowerCase() ===
        value.toLowerCase()
      ) {
        found = true;
      } else {
        remaining.push(
          all[i]
        );
      }
    }

    if (!found) {
      return {
        success: false,
        error:
          "Shelf not found: " +
          value
      };
    }

    /*
     * Existing Books rows are deliberately
     * NOT changed when a shelf is deleted.
     */
    var result =
      saveShelves(
        sheetId,
        remaining
      );

    result.deletedShelf =
      value;

    return result;

  } finally {
    lock.releaseLock();
  }
}

/* ==========================================================
   ISBN / BARCODE
   ========================================================== */

function checkBarcode(
  sheetId,
  barcode
) {
  var code =
    normalizeBarcode_(
      barcode
    );

  if (code === "") {
    return {
      success: false,
      duplicate: false,
      exists: false,
      error:
        "Barcode/ISBN is empty."
    };
  }

  var sheet =
    getBooksSheet(
      sheetId
    );

  var map =
    getHeaderMap_(
      sheet
    );

  var barcodeIndex =
    map["Barcode"];

  if (
    barcodeIndex ===
    undefined
  ) {
    throw new Error(
      "Barcode column not found."
    );
  }

  if (
    sheet.getLastRow() < 2
  ) {
    return {
      success: true,
      duplicate: false,
      exists: false,
      barcode: code,
      message:
        "ISBN is new."
    };
  }

  var values =
    sheet
      .getRange(
        2,
        barcodeIndex + 1,
        sheet.getLastRow() - 1,
        1
      )
      .getDisplayValues();

  var books = [];

  for (
    var i = 0;
    i < values.length;
    i++
  ) {
    if (
      normalizeBarcode_(
        values[i][0]
      ) === code
    ) {
      var row =
        sheet
          .getRange(
            i + 2,
            1,
            1,
            sheet.getLastColumn()
          )
          .getDisplayValues()[0];

      books.push(
        rowToBook_(
          row,
          map
        )
      );
    }
  }

  if (
    books.length === 0
  ) {
    return {
      success: true,
      duplicate: false,
      exists: false,
      barcode: code,
      message:
        "ISBN is new."
    };
  }

  return {
    success: true,
    duplicate: true,
    exists: true,
    barcode: code,
    count: books.length,
    book: books[0],
    books: books,
    message:
      "ISBN already exists in the library."
  };
}

function getBookByBarcode(
  sheetId,
  barcode
) {
  return checkBarcode(
    sheetId,
    barcode
  );
}

/* ==========================================================
   ISBN METADATA
   ========================================================== */

function getBookMetadata(
  isbn
) {
  var code =
    normalizeBarcode_(
      isbn
    );

  if (code === "") {
    return {
      success: false,
      found: false,
      error:
        "ISBN is empty."
    };
  }

  var url =
    "https://www.googleapis.com/books/v1/volumes?q=isbn:" +
    encodeURIComponent(code) +
    "&maxResults=5";

  try {
    var response =
      UrlFetchApp.fetch(
        url,
        {
          method: "get",
          muteHttpExceptions: true
        }
      );

    var status =
      response.getResponseCode();

    if (
      status < 200 ||
      status >= 300
    ) {
      return {
        success: false,
        found: false,
        error:
          "ISBN metadata service HTTP " +
          status
      };
    }

    var data =
      JSON.parse(
        response.getContentText()
      );

    if (
      !data.items ||
      data.items.length === 0
    ) {
      return {
        success: true,
        found: false,
        isbn: code,
        message:
          "No online metadata found. Enter the details manually or use OCR."
      };
    }

    var info =
      data.items[0]
        .volumeInfo || {};

    var identifiers =
      info.industryIdentifiers ||
      [];

    var isbn10 = "";
    var isbn13 = "";

    for (
      var i = 0;
      i < identifiers.length;
      i++
    ) {
      if (
        identifiers[i].type ===
        "ISBN_10"
      ) {
        isbn10 =
          stringValue_(
            identifiers[i]
              .identifier
          );
      }

      if (
        identifiers[i].type ===
        "ISBN_13"
      ) {
        isbn13 =
          stringValue_(
            identifiers[i]
              .identifier
          );
      }
    }

    var languageCode =
      stringValue_(
        info.language
      );

    var authors =
      info.authors || [];

    var subjects =
      info.categories || [];

    return {
      success: true,
      found: true,

      isbn: code,
      isbn10: isbn10,
      isbn13: isbn13,

      title:
        stringValue_(
          info.title
        ),

      subtitle:
        stringValue_(
          info.subtitle
        ),

      author:
        authors.join(", "),

      authors:
        authors,

      publisher:
        stringValue_(
          info.publisher
        ),

      publishedDate:
        stringValue_(
          info.publishedDate
        ),

      edition: "",

      language:
        languageName_(
          languageCode
        ),

      languageCode:
        languageCode,

      subjects:
        subjects.join(", "),

      categories:
        subjects,

      description:
        stringValue_(
          info.description
        ),

      pageCount:
        info.pageCount || "",

      imageUrl:
        info.imageLinks &&
        info.imageLinks.thumbnail
          ? info.imageLinks.thumbnail
          : "",

      source:
        "Google Books"
    };

  } catch (error) {
    return {
      success: false,
      found: false,
      isbn: code,
      error:
        errorMessage_(
          error
        )
    };
  }
}

function languageName_(
  code
) {
  var map = {
    en: "English",
    ml: "Malayalam",
    hi: "Hindi",
    ta: "Tamil",
    kn: "Kannada",
    te: "Telugu",
    bn: "Bengali",
    mr: "Marathi",
    gu: "Gujarati",
    pa: "Punjabi",
    ur: "Urdu",
    fr: "French",
    de: "German",
    es: "Spanish"
  };

  return (
    map[code] ||
    code ||
    ""
  );
}

/* ==========================================================
   STOCK NUMBER
   ========================================================== */

function checkStockNumber(
  sheetId,
  stockNumber
) {
  var stock =
    stringValue_(
      stockNumber
    );

  if (stock === "") {
    return {
      success: false,
      exists: false,
      error:
        "Stock Number is empty."
    };
  }

  var sheet =
    getBooksSheet(
      sheetId
    );

  var map =
    getHeaderMap_(
      sheet
    );

  var index =
    map["Stock Number"];

  if (
    index === undefined
  ) {
    throw new Error(
      "Stock Number column not found."
    );
  }

  if (
    sheet.getLastRow() < 2
  ) {
    return {
      success: true,
      exists: false
    };
  }

  var values =
    sheet
      .getRange(
        2,
        index + 1,
        sheet.getLastRow() - 1,
        1
      )
      .getDisplayValues();

  for (
    var i = 0;
    i < values.length;
    i++
  ) {
    if (
      stringValue_(
        values[i][0]
      ).toLowerCase() ===
      stock.toLowerCase()
    ) {
      return {
        success: true,
        exists: true,
        row: i + 2
      };
    }
  }

  return {
    success: true,
    exists: false
  };
}

function getNextStockNumber(
  sheetId
) {
  var sheet =
    getBooksSheet(
      sheetId
    );

  var map =
    getHeaderMap_(
      sheet
    );

  var index =
    map["Stock Number"];

  if (
    index === undefined
  ) {
    throw new Error(
      "Stock Number column not found."
    );
  }

  if (
    sheet.getLastRow() < 2
  ) {
    return {
      success: true,
      stockNumber: "1"
    };
  }

  var values =
    sheet
      .getRange(
        2,
        index + 1,
        sheet.getLastRow() - 1,
        1
      )
      .getDisplayValues();

  var maximum = 0;

  for (
    var i = 0;
    i < values.length;
    i++
  ) {
    var match =
      stringValue_(
        values[i][0]
      ).match(/\d+/);

    if (match) {
      var number =
        parseInt(
          match[0],
          10
        );

      if (
        !isNaN(number) &&
        number > maximum
      ) {
        maximum = number;
      }
    }
  }

  return {
    success: true,
    stockNumber:
      String(maximum + 1)
  };
}

/* ==========================================================
   BOOK NORMALIZATION
   ========================================================== */

function normalizeBook_(
  book
) {
  book =
    book || {};

  var aliases = {
    stockNumber:
      "Stock Number",
    stock_number:
      "Stock Number",

    callNumber:
      "Call Number",
    call_number:
      "Call Number",

    title:
      "Title",

    author:
      "Author",

    language:
      "Language",

    category:
      "Category",

    price:
      "Price",

    publisher:
      "Publisher",

    edition:
      "Edition",

    shelf:
      "Shelf",

    barcode:
      "Barcode",

    isbn:
      "Barcode",

    bookType:
      "Book Type",

    book_type:
      "Book Type",

    status:
      "Status",

    subjects:
      "Subjects"
  };

  var result =
    {};

  var keys =
    Object.keys(book);

  for (
    var i = 0;
    i < keys.length;
    i++
  ) {
    var key =
      keys[i];

    var target =
      aliases[key] ||
      key;

    result[target] =
      book[key];
  }

  for (
    var j = 0;
    j < REQUIRED_COLUMNS.length;
    j++
  ) {
    var column =
      REQUIRED_COLUMNS[j];

    if (
      result[column] ===
        undefined ||
      result[column] ===
        null
    ) {
      result[column] = "";
    } else {
      result[column] =
        String(
          result[column]
        );
    }
  }

  result["Barcode"] =
    normalizeBarcode_(
      result["Barcode"]
    );

  return result;
}

/* ==========================================================
   ADD BOOK
   ========================================================== */

function addBook(
  sheetId,
  book,
  allowDuplicateBarcode
) {
  book =
    normalizeBook_(
      book
    );

  var sheet =
    getBooksSheet(
      sheetId
    );

  var map =
    getHeaderMap_(
      sheet
    );

  var lock =
    LockService.getScriptLock();

  lock.waitLock(
    20000
  );

  try {
    if (
      stringValue_(
        book["Stock Number"]
      ) === ""
    ) {
      book["Stock Number"] =
        getNextStockNumber(
          sheetId
        ).stockNumber;
    }

    var stockCheck =
      checkStockNumber(
        sheetId,
        book["Stock Number"]
      );

    if (
      stockCheck.exists
    ) {
      return {
        success: false,
        error:
          "Duplicate Stock Number: " +
          book["Stock Number"]
      };
    }

    /*
     * Duplicate ISBN is allowed for
     * multiple physical copies when
     * allowDuplicateBarcode=true.
     */
    if (
      book["Barcode"] !== "" &&
      allowDuplicateBarcode !==
        true
    ) {
      var barcodeCheck =
        checkBarcode(
          sheetId,
          book["Barcode"]
        );

      if (
        barcodeCheck.exists
      ) {
        return {
          success: false,
          duplicate: true,
          error:
            "This ISBN/Barcode already exists. " +
            "Use allowDuplicateBarcode=true " +
            "for another physical copy.",
          book:
            barcodeCheck.book ||
            null
        };
      }
    }

    /*
     * Call Number is the only field
     * that is not expected to come
     * from OCR. If it is empty,
     * generate it automatically.
     */
    if (
      stringValue_(
        book["Call Number"]
      ) === ""
    ) {
      var generated =
        generateCallNumber(
          sheetId,
          book
        );

      if (
        generated.success
      ) {
        book["Call Number"] =
          generated.callNumber;
      }
    }

    var row =
      new Array(
        sheet.getLastColumn()
      ).fill("");

    var keys =
      Object.keys(map);

    for (
      var i = 0;
      i < keys.length;
      i++
    ) {
      var key =
        keys[i];

      if (
        Object.prototype.hasOwnProperty.call(
          book,
          key
        )
      ) {
        row[map[key]] =
          book[key];
      }
    }

    sheet.appendRow(row);

    return {
      success: true,
      message:
        "Book added successfully.",
      stockNumber:
        book["Stock Number"],
      callNumber:
        book["Call Number"],
      book:
        book
    };

  } finally {
    lock.releaseLock();
  }
}

/* ==========================================================
   UPDATE BOOK
   ========================================================== */

function updateBook(
  sheetId,
  stockNumber,
  book
) {
  var stock =
    stringValue_(
      stockNumber
    );

  if (stock === "") {
    return {
      success: false,
      error:
        "Stock Number is required."
    };
  }

  var sheet =
    getBooksSheet(
      sheetId
    );

  var map =
    getHeaderMap_(
      sheet
    );

  var stockIndex =
    map["Stock Number"];

  if (
    stockIndex ===
    undefined
  ) {
    throw new Error(
      "Stock Number column not found."
    );
  }

  if (
    sheet.getLastRow() < 2
  ) {
    return {
      success: false,
      error:
        "Book not found."
    };
  }

  var rows =
    sheet
      .getRange(
        2,
        1,
        sheet.getLastRow() - 1,
        sheet.getLastColumn()
      )
      .getValues();

  var rowNumber = -1;

  for (
    var i = 0;
    i < rows.length;
    i++
  ) {
    if (
      stringValue_(
        rows[i][stockIndex]
      ).toLowerCase() ===
      stock.toLowerCase()
    ) {
      rowNumber =
        i + 2;
      break;
    }
  }

  if (
    rowNumber === -1
  ) {
    return {
      success: false,
      error:
        "Book not found for Stock Number " +
        stock
    };
  }

  var current =
    rows[
      rowNumber - 2
    ];

  var currentBook =
    rowToBook_(
      current,
      map
    );

  var updatedBook =
    normalizeBook_(
      book
    );

  var merged = {};

  var currentKeys =
    Object.keys(
      currentBook
    );

  for (
    var j = 0;
    j < currentKeys.length;
    j++
  ) {
    merged[
      currentKeys[j]
    ] =
      currentBook[
        currentKeys[j]
      ];
  }

  var newKeys =
    Object.keys(
      updatedBook
    );

  for (
    var k = 0;
    k < newKeys.length;
    k++
  ) {
    merged[
      newKeys[k]
    ] =
      updatedBook[
        newKeys[k]
      ];
  }

  merged[
    "Stock Number"
  ] = stock;

  var row =
    bookToRow_(
      merged,
      map,
      current
    );

  sheet
    .getRange(
      rowNumber,
      1,
      1,
      row.length
    )
    .setValues([
      row
    ]);

  return {
    success: true,
    message:
      "Book updated successfully.",
    book:
      merged
  };
}

/* ==========================================================
   GET BOOK
   ========================================================== */

function getBook(
  sheetId,
  stockNumber
) {
  var stock =
    stringValue_(
      stockNumber
    );

  if (stock === "") {
    return {
      success: false,
      error:
        "Stock Number is required."
    };
  }

  var sheet =
    getBooksSheet(
      sheetId
    );

  var map =
    getHeaderMap_(
      sheet
    );

  var stockIndex =
    map["Stock Number"];

  if (
    sheet.getLastRow() < 2
  ) {
    return {
      success: false,
      error:
        "Book not found."
    };
  }

  var rows =
    sheet
      .getRange(
        2,
        1,
        sheet.getLastRow() - 1,
        sheet.getLastColumn()
      )
      .getDisplayValues();

  for (
    var i = 0;
    i < rows.length;
    i++
  ) {
    if (
      stringValue_(
        rows[i][stockIndex]
      ).toLowerCase() ===
      stock.toLowerCase()
    ) {
      return {
        success: true,
        book:
          rowToBook_(
            rows[i],
            map
          )
      };
    }
  }

  return {
    success: false,
    error:
      "Book not found for Stock Number " +
      stock
  };
}

/* ==========================================================
   SEARCH
   ========================================================== */

function searchBooks(
  sheetId,
  query
) {
  var q =
    stringValue_(
      query
    ).toLowerCase();

  var sheet =
    getBooksSheet(
      sheetId
    );

  var map =
    getHeaderMap_(
      sheet
    );

  if (
    sheet.getLastRow() < 2
  ) {
    return {
      success: true,
      results: [],
      books: [],
      count: 0
    };
  }

  var rows =
    sheet
      .getRange(
        2,
        1,
        sheet.getLastRow() - 1,
        sheet.getLastColumn()
      )
      .getDisplayValues();

  var results = [];

  for (
    var i = 0;
    i < rows.length;
    i++
  ) {
    var book =
      rowToBook_(
        rows[i],
        map
      );

    if (q === "") {
      results.push(book);
      continue;
    }

    var searchable = [
      book["Stock Number"],
      book["Call Number"],
      book["Title"],
      book["Author"],
      book["Language"],
      book["Category"],
      book["Price"],
      book["Publisher"],
      book["Edition"],
      book["Shelf"],
      book["Barcode"],
      book["Book Type"],
      book["Status"],
      book["Subjects"]
    ]
      .join(" ")
      .toLowerCase();

    if (
      searchable.indexOf(q) !== -1
    ) {
      results.push(book);
    }
  }

  return {
    success: true,
    results: results,
    books: results,
    count: results.length
  };
}

/* ==========================================================
   CALL NUMBER
   ========================================================== */

function generateCallNumber(
  sheetId,
  book
) {
  book =
    normalizeBook_(
      book
    );

  var category =
    stringValue_(
      book["Category"]
    );

  var author =
    stringValue_(
      book["Author"]
    );

  var title =
    stringValue_(
      book["Title"]
    );

  if (
    category === "" &&
    author === "" &&
    title === ""
  ) {
    return {
      success: false,
      error:
        "Enter Category, Author or Title first."
    };
  }

  var prefixes = {
    Novel: "MN",
    Stories: "MS",
    Essays: "ME",
    Drama: "MD",
    Biography: "MB",
    Poems: "MP",
    Travelogue: "MT",
    Balasahithyam: "BS",
    History: "MH"
  };

  var prefix =
    prefixes[category];

  if (!prefix) {
    prefix =
      makeCategoryPrefix_(
        category
      );
  }

  var authorCode =
    makeThreeLetterCode_(
      author
    );

  var titleCode =
    makeThreeLetterCode_(
      title
    );

  var callNumber =
    prefix;

  if (
    authorCode !== ""
  ) {
    callNumber +=
      "-" + authorCode;
  }

  if (
    titleCode !== ""
  ) {
    callNumber +=
      "-" + titleCode;
  }

  return {
    success: true,
    callNumber:
      callNumber,
    prefix:
      prefix,
    authorCode:
      authorCode,
    titleCode:
      titleCode
  };
}

function makeCategoryPrefix_(
  category
) {
  var text =
    transliterateMalayalam_(
      category
    )
      .toUpperCase()
      .replace(
        /[^A-Z]/g,
        ""
      );

  if (text === "") {
    return "BK";
  }

  return text.substring(
    0,
    3
  );
}

function makeThreeLetterCode_(
  value
) {
  var text =
    transliterateMalayalam_(
      value
    )
      .toUpperCase()
      .replace(
        /[^A-Z]/g,
        ""
      );

  text =
    text
      .replace(
        /^THE/,
        ""
      )
      .replace(
        /^A/,
        ""
      );

  return text.substring(
    0,
    3
  );
}

/* ==========================================================
   MALAYALAM TRANSLITERATION
   ========================================================== */

function transliterateMalayalam_(
  text
) {
  text =
    stringValue_(
      text
    );

  if (text === "") {
    return "";
  }

  var vowels = {
    "അ": "a",
    "ആ": "aa",
    "ഇ": "i",
    "ഈ": "ee",
    "ഉ": "u",
    "ഊ": "oo",
    "ഋ": "r",
    "എ": "e",
    "ഏ": "e",
    "ഐ": "ai",
    "ഒ": "o",
    "ഓ": "o",
    "ഔ": "au"
  };

  var consonants = {
    "ക": "k",
    "ഖ": "kh",
    "ഗ": "g",
    "ഘ": "gh",
    "ങ": "ng",
    "ച": "ch",
    "ഛ": "chh",
    "ജ": "j",
    "ഝ": "jh",
    "ഞ": "nj",
    "ട": "t",
    "ഠ": "th",
    "ഡ": "d",
    "ഢ": "dh",
    "ണ": "n",
    "ത": "t",
    "ഥ": "th",
    "ദ": "d",
    "ധ": "dh",
    "ന": "n",
    "പ": "p",
    "ഫ": "ph",
    "ബ": "b",
    "ഭ": "bh",
    "മ": "m",
    "യ": "y",
    "ര": "r",
    "ല": "l",
    "വ": "v",
    "ശ": "sh",
    "ഷ": "sh",
    "സ": "s",
    "ഹ": "h",
    "ള": "l",
    "ഴ": "zh",
    "റ": "r"
  };

  var signs = {
    "ാ": "aa",
    "ി": "i",
    "ീ": "ee",
    "ു": "u",
    "ൂ": "oo",
    "ൃ": "r",
    "െ": "e",
    "േ": "e",
    "ൈ": "ai",
    "ൊ": "o",
    "ോ": "o",
    "ൌ": "au"
  };

  var output = "";
  var i = 0;

  while (
    i < text.length
  ) {
    var ch =
      text.charAt(i);

    if (vowels[ch]) {
      output +=
        vowels[ch];
      i++;
      continue;
    }

    if (
      consonants[ch]
    ) {
      var value =
        consonants[ch];

      var j =
        i + 1;

      var hasVowel =
        false;

      if (
        j < text.length &&
        signs[
          text.charAt(j)
        ]
      ) {
        value +=
          signs[
            text.charAt(j)
          ];

        hasVowel =
          true;

        j++;
      }

      if (
        j < text.length &&
        text.charAt(j) ===
          "്"
      ) {
        j++;
        hasVowel =
          true;
      }

      if (!hasVowel) {
        value += "a";
      }

      output +=
        value;

      i = j;
      continue;
    }

    if (signs[ch]) {
      output +=
        signs[ch];

      i++;
      continue;
    }

    if (
      /[A-Za-z0-9]/.test(ch) ||
      /\s/.test(ch)
    ) {
      output += ch;
    }

    i++;
  }

  return output;
}

/* ==========================================================
   VALIDATION
   ========================================================== */

function validateSheet(
  sheetUrl
) {
  try {
    var id =
      extractSheetId_(
        sheetUrl
      );

    if (id === "") {
      return {
        success: false,
        valid: false,
        error:
          "Google Sheet URL/ID is empty."
      };
    }

    var ss =
      openSpreadsheet(
        id
      );

    var sheet = findExistingBooksSheet_(ss);

    if (!sheet) {
      return {
        success: false,
        valid: false,
        error:
          "Books sheet not found. Expected a Books sheet or the current E.V.Library Form Responses 1 sheet."
      };
    }

    var map =
      getHeaderMap_(
        sheet
      );

    var missing = [];

    for (
      var i = 0;
      i < REQUIRED_COLUMNS.length;
      i++
    ) {
      if (
        map[
          REQUIRED_COLUMNS[i]
        ] === undefined
      ) {
        missing.push(
          REQUIRED_COLUMNS[i]
        );
      }
    }

    return {
      success: true,
      valid:
        missing.length === 0,
      spreadsheet:
        ss.getName(),
      sheet:
        sheet.getName(),
      missingColumns:
        missing,
      headers:
        Object.keys(map)
    };

  } catch (error) {
    return {
      success: false,
      valid: false,
      error:
        errorMessage_(error)
    };
  }
}

/* ==========================================================
   BACKEND TEST
   ========================================================== */

function testLibraryBackend(sheetId) {
  var targetSheetId = sheetId || DEFAULT_SHEET_ID;
  var ss =
    openSpreadsheet(
      targetSheetId
    );

  var validation =
    validateSheet(
      targetSheetId
    );

  var config =
    getConfig(
      targetSheetId
    );

  var shelfInfo =
    getShelves(
      targetSheetId,
      0,
      8
    );

  return {
    success:
      validation.success &&
      validation.valid &&
      config.success,

    spreadsheet:
      ss.getName(),

    validation:
      validation,

    configSummary: {
      categories:
        config.categories.length,
      languages:
        config.languages.length,
      shelves:
        config.shelves.length,
      bookTypes:
        config.bookTypes.length,
      statuses:
        config.statuses.length
    },

    shelfSummary: {
      firstPage:
        shelfInfo.shelves,
      pageSize:
        shelfInfo.pageSize,
      totalShelves:
        shelfInfo.totalShelves,
      totalPages:
        shelfInfo.totalPages
    }
  };
}
