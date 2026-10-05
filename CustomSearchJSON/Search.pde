/*
  Performs one Google Custom Search API query, downloads the returned images and
  records them in the index files.

  SECURITY: this file used to contain a live Google API key and a search engine
  id, one of them inside a commented-out URL - which is still a committed
  secret and is still in the git history. Both are now read from the
  environment. See .env.example and SECURITY.md; if you are the owner of this
  repository, rotate the key that was committed. The exposed value is
  deliberately not reproduced here.

  Also fixed here:
    - no connect or read timeout, so a hung endpoint froze draw() forever;
    - the response reader was never closed and disconnect() was not reached on
      the failure path, so every query leaked a socket;
    - the response status was never checked, so an error page was parsed as if
      it were a result set;
    - query parameters were concatenated raw, so a search term could append or
      truncate parameters of the outgoing request;
    - the result loop was hard-coded to ten items, which threw
      IndexOutOfBoundsException on any short page (that is, at the end of every
      query) and NullPointerException when items was absent;
    - catch (Error) swallowed OutOfMemoryError and StackOverflowError as if they
      were recoverable.
*/
import com.precog.processing.core.SafeLog;
import com.precog.processing.core.SearchQuery;
import com.precog.processing.core.SearchResults;
import com.precog.processing.core.SecureFetch;

import java.io.IOException;
import java.io.InputStream;

import javax.net.ssl.HttpsURLConnection;

import com.google.gson.Gson;

// Search terms to iterate over. Edit locally; never commit credentials here.
String qry        = "picasso paintings";
String fileType   = "png,jpg";
String searchType = "image";

int RESULTS_PER_PAGE = 10;
int MAX_RESPONSE_BYTES = 8 * 1024 * 1024;

// Environment variable names holding the Custom Search credentials. Both are
// required and neither has a default.
String API_KEY_ENV   = "GOOGLE_CUSTOM_SEARCH_API_KEY";
String ENGINE_ID_ENV = "GOOGLE_CUSTOM_SEARCH_ENGINE_ID";

SafeLog log = SafeLog.toStdout("Search");

/**
 * Runs one search page.
 *
 * @param index 1-based start index of the page to fetch
 * @return the start index of the next page, or the first index once the last
 *     available page has been reached
 * @throws IOException if the request fails, times out, or the response cannot
 *     be parsed
 * @throws IllegalStateException if a required environment variable is unset
 */
int Search(int index) throws IOException {

  SearchQuery query = new SearchQuery(
    requireEnv(API_KEY_ENV),
    requireEnv(ENGINE_ID_ENV),
    qry,
    fileType,
    searchType,
    index,
    RESULTS_PER_PAGE);

  log.info("requesting page from index " + index + ", up to " + query.pageSize() + " results");

  SearchResults page = SearchResults.of(fetch(query).links());

  log.info("received " + page.size() + " usable image links");

  int stored = 0;
  for (int i = 0; i < page.size(); i++) {
    String link = page.linkAt(i);
    try {
      WebImage webImg = new WebImage(link);
      if (webImg.nullImage) {
        continue;
      }
      webImg.saveImage();
      imagesWeb.add(webImg);
      wrXML.writeNewImage(i + index, link);
      stored++;
    }
    catch (Exception e) {
      // One bad result must not abandon the rest of the page.
      log.warn("skipped result " + (i + index) + ": " + e.getMessage(), e);
    }
  }

  log.info("stored " + stored + " of " + page.size() + " results");

  if (query.isLastPage()) {
    log.info("last available page reached, wrapping to the start of the result set");
    return SearchQuery.MIN_START_INDEX;
  }
  return query.nextStartIndex();
}

/** Reads a credential from the environment; never falls back to a default. */
String requireEnv(String name) {
  String value = System.getenv(name);
  if (value == null || value.trim().isEmpty()) {
    throw new IllegalStateException(
      "Missing required environment variable " + name
      + ". See .env.example for how to set it; credentials are deliberately"
      + " not committed to this repository.");
  }
  return value.trim();
}

/** Performs the request and deserialises the response. */
GResults fetch(SearchQuery query) throws IOException {
  HttpsURLConnection conn = SecureFetch.openHttps(query.toUrl());
  try {
    InputStream in = conn.getInputStream();
    try {
      String body = new String(SecureFetch.readAll(in, MAX_RESPONSE_BYTES), "UTF-8");
      GResults parsed = new Gson().fromJson(body, GResults.class);
      if (parsed == null) {
        throw new IOException("The search API returned no parseable document");
      }
      return parsed;
    }
    finally {
      SecureFetch.closeQuietly(in);
    }
  }
  catch (RuntimeException e) {
    // Gson reports malformed JSON with unchecked exceptions.
    throw new IOException("Could not parse the search response: " + e.getMessage(), e);
  }
  finally {
    conn.disconnect();
  }
}