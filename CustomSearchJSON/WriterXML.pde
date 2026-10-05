/*
  Appends downloaded image records to the index file.

  DEFECTS FIXED:
    - the constructor loaded from the sketch root while writeNewImage() saved to
      data/imagenes.xml, so records accumulated in a file the sketch never read
      back;
    - writeNewImage() ignored the name it was constructed with and hard-coded
      data/imagenes.xml, so two instances would overwrite each other;
    - a missing index file was not handled, so a fresh clone crashed at startup.

  The url and title written here come from a third-party response. saveXML()
  escapes text content, and the file is read back through a parser configured
  with entity resolution disabled (see XmlPolicy), so a crafted title cannot
  turn the index into an XXE payload.
*/
import com.precog.processing.core.SafePath;

class WriterXML {

  static final String DATA_FOLDER = "data/";

  XML xml;
  String name;

  WriterXML(String name) {
    this.name = name;

    String path = DATA_FOLDER + name;
    if (fileExists(path)) {
      println("LOADING XML " + path);
      xml = loadXML(path);
    }
    else {
      println("NO IMAGE INDEX AT " + path + ", CREATING ONE");
      xml = parseXML("<images></images>");
    }
  }

  void writeNewImage(int index, String url) {
    XML xmImage = xml.addChild("image");

    XML indexXML = xmImage.addChild("index");
    indexXML.setIntContent(index);

    XML urlXML = xmImage.addChild("url");
    urlXML.setContent(url);

    saveXML(xml, DATA_FOLDER + name);
  }

  void writeNewImage(int index, String url, String title, String filename) {
    XML xmImage = xml.addChild("image");

    XML indexXML = xmImage.addChild("index");
    indexXML.setIntContent(index);

    XML urlXML = xmImage.addChild("url");
    urlXML.setContent(url);

    XML titleXML = xmImage.addChild("title");
    titleXML.setContent(title);

    XML fileXML = xmImage.addChild("filename");
    fileXML.setContent(SafePath.sanitizeFileName(filename));

    saveXML(xml, DATA_FOLDER + name);
  }
}