/*
  Reads and updates the cursor that records how far the search has progressed.

  DEFECTS FIXED:
    - the constructor loaded "lastIndex.xml" from the sketch root while
      writeLastIndex() saved to "data/lastIndex.xml", so the value written was
      never the value read and the root file drifted out of date;
    - readLastIndex() called getChild("index").getIntContent() with no null
      check, so a truncated or hand-edited file killed the sketch at startup;
    - readLastIndex() logged the this.lastIndex field, which is always 0 at
      that point, instead of the value it had just read.
*/
class IndexXML {

  static final String DATA_FOLDER = "data/";

  XML xml;
  int lastIndex;
  String name;

  IndexXML(String name) {
    this.name = name;

    String path = DATA_FOLDER + name;
    if (fileExists(path)) {
      println("LOADING XML " + path);
      xml = loadXML(path);
    }
    else {
      println("NO INDEX FILE AT " + path + ", STARTING FROM 1");
      xml = parseXML("<lastIndex><index>1</index></lastIndex>");
    }

    lastIndex = readLastIndex();
  }

  /** @return the stored cursor, or 1 when the file is absent or unreadable. */
  int readLastIndex() {
    XML child = xml.getChild("index");
    if (child == null) {
      println("NO <index> ELEMENT, DEFAULTING TO 1");
      return 1;
    }

    int value = child.getIntContent();
    if (value < 1) {
      println("INDEX " + value + " IS OUT OF RANGE, DEFAULTING TO 1");
      return 1;
    }

    println("INDEX " + value);
    return value;
  }

  void writeLastIndex(int lastIndex) {
    XML[] children = xml.getChildren("index");
    for (int i = 0; i < children.length; i++) {
      xml.removeChild(children[i]);
    }

    this.lastIndex = lastIndex;

    XML xmLImage = xml.addChild("index");
    xmLImage.setIntContent(lastIndex);

    println("LAST INDEX " + lastIndex);
    saveXML(xml, DATA_FOLDER + name);
  }
}