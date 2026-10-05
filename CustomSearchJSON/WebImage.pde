/*
  Downloads a single image referenced by a Custom Search API result and stores
  it under the sketch's data/ folder.

  SECURITY: the URL arrives from a third-party response, so it is untrusted
  input on two separate paths:

    1. it became a local file name. The original implementation took the last
       '/' segment of the URL and wrote it under data/, which is a directory
       traversal / arbitrary file write primitive (a remote side could return
       ../../.bashrc). SafePath.sanitizeFileName() now reduces it to a name
       that cannot contain a separator, and SafePath.resolveUnder() re-checks
       the canonical path before anything is written.

    2. it is dereferenced. loadImage() follows whatever URL it is handed, with
       no timeout and no size limit, so a slow or hostile endpoint can wedge the
       draw() loop or exhaust the heap. SecureFetch applies connect and read
       timeouts and refuses to buffer more than MAX_IMAGE_BYTES.
*/
import com.precog.processing.core.SafeLog;
import com.precog.processing.core.SafePath;
import com.precog.processing.core.SecureFetch;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;

class WebImage {

  // A generous ceiling for a single image, and small enough that a hostile or
  // malfunctioning endpoint cannot take the sketch down with it.
  static final int MAX_IMAGE_BYTES = 32 * 1024 * 1024;

  static final String DATA_FOLDER = "data/";

  SafeLog log = SafeLog.toStdout("WebImage");

  PImage imageWeb;
  String path;
  String name;

  boolean nullImage = false;

  WebImage(String path) {
    this.path = path;

    byte[] payload = fetch();
    if (payload == null) {
      nullImage = true;
      return;
    }

    try {
      // Already validated and size-bounded by fetch(); decoding is now local.
      imageWeb = loadImage(new ByteArrayInputStream(payload));
      nullImage = false;
    }
    catch (RuntimeException e) {
      // loadImage throws RuntimeException subclasses for corrupt data.
      log.warn("could not decode image from " + SafeLog.redact(path), e);
      imageWeb = null;
      nullImage = true;
    }
  }

  void draw() {
    if (imageWeb != null) {
      image( imageWeb, 0, 0, width, height );
    }
  }

  void saveImage() {
    if (imageWeb == null) {
      return;
    }
    try {
      // resolveUnder() throws rather than returning a path outside data/.
      File target = SafePath.resolveUnder(DATA_FOLDER, name);

      if ( target.exists() ) {
        log.debug("already stored, skipping " + target.getName());
        return;
      }

      imageWeb.save( target.getPath() );
      log.info("stored " + target.getName());
    }
    catch (IOException e) {
      log.error("could not resolve a writable path under " + DATA_FOLDER, e);
    }
    catch (RuntimeException e) {
      log.error("could not store image for " + SafeLog.redact(path), e);
    }
  }

  /**
   * Reduces an untrusted URL to a safe local file name.
   *
   * <p>Kept as a method because the original class exposed checkPath() and it
   * reads clearly at the call site; all of the security work happens in
   * SafePath, which is unit tested.
   */
  String checkPath(String s) {
    name = SafePath.sanitizeFileName(s);
    return name;
  }

  private byte[] fetch() {
    name = checkPath(path);

    try {
      javax.net.ssl.HttpsURLConnection conn =
        SecureFetch.openHttps(path, 10000, 20000, 3);

      try {
        InputStream in = conn.getInputStream();
        try {
          return SecureFetch.readAll(in, MAX_IMAGE_BYTES);
        }
        finally {
          SecureFetch.closeQuietly(in);
        }
      }
      finally {
        conn.disconnect();
      }
    }
    catch (IOException e) {
      log.warn("skipping unreachable image " + SafeLog.redact(path), e);
      return null;
    }
    catch (RuntimeException e) {
      log.warn("skipping invalid image URL " + SafeLog.redact(path), e);
      return null;
    }
  }
}