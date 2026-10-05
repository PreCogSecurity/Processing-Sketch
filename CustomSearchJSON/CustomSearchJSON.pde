/*
  Iterates the pages of the Google Custom Search API, downloading and storing
  the images it finds and letting you page through them.

  Keys:
    a / s   previous / next image on the current page
    m       print the persisted search cursor

  RELIABILITY FIXES:
    - the per-page error handling caught only checked IO exceptions, so a missing
      credential or a malformed response escaped draw() and killed the sketch;
    - on failure the cursor was still rewritten and the cached images were still
      discarded, so a transient network error destroyed the page you were
      looking at and rewound progress;
    - currIndexImages was never reset when the page changed, so the new page
      could start out of bounds and draw() would throw.
*/
import com.precog.processing.core.SafeLog;
import com.precog.processing.core.SearchQuery;

ArrayList imagesWeb;

int currIndexImages = 0;
int startIndex      = 1;

int tmpIndex        = 0;

PFont f;

// XML index readers and writers.
IndexXML  rdXML;
WriterXML wrXML;

Timer time;

SafeLog log = SafeLog.toStdout("CustomSearchJSON");

void setup() {
  size(300, 300);

  f = createFont("Georgia", 16);
  textFont(f);

  rdXML = new IndexXML("lastIndex.xml");
  wrXML = new WriterXML("imagenes.xml");

  startIndex = rdXML.readLastIndex();
  tmpIndex   = startIndex;

  log.info("starting at index " + startIndex);

  imagesWeb = new ArrayList();

  time = new Timer(int(60000 * 3.0));
}

void draw() {
  background(0);

  if (!imagesWeb.isEmpty()) {
    if (currIndexImages >= imagesWeb.size()) {
      currIndexImages = imagesWeb.size() - 1;
    }
    if (currIndexImages < 0) {
      currIndexImages = 0;
    }
    WebImage wImg = (WebImage) imagesWeb.get(currIndexImages);
    wImg.draw();
  }

  time.update();

  float tm = time.getCurrentTime();
  text(tm, 50, 50);
  text(((time.end == true) ? "true" : "false"), 50, 80);
  text(tmpIndex, 50, 120);

  if (time.end == true) {
    fetchNextPage();
  }
}

/** Runs one search page. A failure leaves the current page on screen. */
void fetchNextPage() {
  int nextIndex;
  try {
    nextIndex = Search(tmpIndex);
  }
  catch (Exception e) {
    // Covers the IOException from fetch() and the IllegalStateException raised
    // when a credential is missing.
    log.error("search failed, keeping the current page: " + e.getMessage(), e);
    time.restart();
    return;
  }

  startIndex = nextIndex;
  tmpIndex   = nextIndex;
  rdXML.writeLastIndex(startIndex);

  imagesWeb.clear();
  currIndexImages = 0;
  time.restart();
}

void keyPressed() {
  if (key == 'a') {
    if (currIndexImages > 0) {
      currIndexImages--;
    }
  }

  if (key == 's') {
    if (currIndexImages < imagesWeb.size() - 1) {
      currIndexImages++;
    }
  }

  if (key == 'm') {
    log.info("persisted cursor: " + rdXML.readLastIndex());
  }

  if (key == 'n') {
    // Moves the persisted cursor to an arbitrary valid page.
    int target = 1 + int(random(max(1, SearchQuery.MAX_START_INDEX)));
    log.info("cursor moved to " + target);
    rdXML.writeLastIndex(target);
  }
}