// generate-profiles.js -- builds the Oceanic Next Terminal.app profiles
//
//   osascript -l JavaScript terminal/generate-profiles.js terminal
//
// Writes "Oceanic Next Dark.terminal" and "Oceanic Next Light.terminal" into
// the given folder. Uses only macOS's built-in JavaScript for Automation, so no
// dependencies. The colors match the vimrc palettes; edit them below and re-run.
//
// The font is copied from Terminal's built-in "Clear Dark" profile when it
// exists (the system monospace font), otherwise the system monospace font is
// used directly.

ObjC.import('AppKit');

const PROFILES = {
  'Oceanic Next Dark': {
    background: '#1B2B34', text: '#C0C5CE', bold: '#D8DEE9',
    cursor: '#C0C5CE', selection: '#4F5B66',
    ansi: {
      Black: '#343D46',   BrightBlack: '#65737E',
      Red: '#EC5F67',     BrightRed: '#EC5F67',
      Green: '#99C794',   BrightGreen: '#99C794',
      Yellow: '#FAC863',  BrightYellow: '#FAC863',
      Blue: '#6699CC',    BrightBlue: '#6699CC',
      Magenta: '#C594C5', BrightMagenta: '#C594C5',
      Cyan: '#5FB3B3',    BrightCyan: '#5FB3B3',
      White: '#C0C5CE',   BrightWhite: '#D8DEE9',
    },
  },
  'Oceanic Next Light': {
    background: '#EEF1F5', text: '#2E3A44', bold: '#1B2B34',
    cursor: '#2E3A44', selection: '#C9D7E8',
    ansi: {
      Black: '#343D46',   BrightBlack: '#5E6B76',
      Red: '#BF3740',     BrightRed: '#BF3740',
      Green: '#3B7536',   BrightGreen: '#3B7536',
      Yellow: '#856400',  BrightYellow: '#856400',
      Blue: '#2F62A0',    BrightBlue: '#2F62A0',
      Magenta: '#8A4B8A', BrightMagenta: '#8A4B8A',
      Cyan: '#1C7070',    BrightCyan: '#1C7070',
      White: '#C0C5CE',   BrightWhite: '#D8DEE7',
    },
  },
};

const COLUMNS = 120;
const ROWS = 30;
const FONT_SIZE = 12;

function archive(obj) {
  return $.NSKeyedArchiver.archivedDataWithRootObjectRequiringSecureCodingError(obj, true, null);
}

function color(hex) {
  const n = parseInt(hex.slice(1), 16);
  return archive($.NSColor.colorWithSRGBRedGreenBlueAlpha(
    ((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255, 1));
}

function fontData() {
  const defaults = $.NSUserDefaults.alloc.initWithSuiteName('com.apple.Terminal');
  const all = defaults.objectForKey('Window Settings');
  const base = all.isNil() ? $() : all.objectForKey('Clear Dark');
  if (!base.isNil() && !base.objectForKey('Font').isNil()) return base.objectForKey('Font');
  return archive($.NSFont.monospacedSystemFontOfSizeWeight(FONT_SIZE, 0));
}

function run(argv) {
  if (argv.length !== 1) throw new Error('usage: osascript -l JavaScript generate-profiles.js <output folder>');
  const outDir = argv[0];
  const font = fontData();
  const written = [];

  for (const [name, p] of Object.entries(PROFILES)) {
    const d = $.NSMutableDictionary.dictionary;
    const set = (k, v) => d.setObjectForKey(v, k);

    set('name', $(name));
    set('type', $('Window Settings'));
    set('ProfileCurrentVersion', $(2.09));
    set('Font', font);
    set('FontAntialias', $(true));
    set('FontWidthSpacing', $(1));
    set('FontHeightSpacing', $(1));
    set('columnCount', $(COLUMNS));
    set('rowCount', $(ROWS));

    // Opaque, so Terminal's background matches the solid background Vim paints
    set('BackgroundColor', color(p.background));
    set('BackgroundBlur', $(0));
    set('BackgroundSettingsForInactiveWindows', $(false));

    set('TextColor', color(p.text));
    set('TextBoldColor', color(p.bold));
    set('CursorColor', color(p.cursor));
    set('SelectionColor', color(p.selection));
    set('DynamicANSIForegroundColors', $(false));
    for (const [slot, hex] of Object.entries(p.ansi)) set(`ANSI${slot}Color`, color(hex));

    const path = `${outDir}/${name}.terminal`;
    if (!d.writeToFileAtomically(path, true)) throw new Error(`could not write ${path}`);
    written.push(path);
  }
  return written.join('\n');
}
