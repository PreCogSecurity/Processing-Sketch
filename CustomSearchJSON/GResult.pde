/*
  Gson data model for the Google Custom Search API response.

  SECURITY / RELIABILITY: items is optional in the API response - it is absent
  on a zero-result query and shorter than the requested page size on the last
  page. The original accessors (getThing(int) and getLink(int)) indexed that
  list without checking, so the sketch threw NullPointerException or
  IndexOutOfBoundsException and died. links() below returns a list that is
  never null and never contains a null or blank entry, and the sketch iterates
  that list by its own size.
*/
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class GResults {

  public String link;
  public String htmlFormattedUrl;

  public List<GResults> items;

  public String getLink() {
    return link;
  }

  public String getUrl() {
    return htmlFormattedUrl;
  }

  public void setUrl(String htmlFormattedUrl) {
    this.htmlFormattedUrl = htmlFormattedUrl;
  }

  public List<GResults> getItems() {
    return items;
  }

  public void setLink(String link) {
    this.link = link;
  }

  public void setGroups(List<GResults> items) {
    this.items = items;
  }

  /**
   * @return the links of every usable item on this page, never {@code null},
   *     with null and blank entries removed
   */
  public List<String> links() {
    if (items == null) {
      return Collections.emptyList();
    }

    List<String> collected = new ArrayList<String>(items.size());
    for (int i = 0; i < items.size(); i++) {
      GResults item = items.get(i);
      if (item == null || item.link == null || item.link.trim().isEmpty()) {
        continue;
      }
      collected.add(item.link.trim());
    }
    return collected;
  }

  /**
   * @return the number of items actually present, which is not the page size
   *     the API was asked for
   */
  public int itemCount() {
    return items == null ? 0 : items.size();
  }

  public void getThing(int i) {
    GResults item = itemAt(i);
    if (item == null) {
      return;
    }
    System.out.println(item);
  }

  /** Bounds-safe accessor; returns {@code null} instead of throwing. */
  public GResults itemAt(int i) {
    if (items == null || i < 0 || i >= items.size()) {
      return null;
    }
    return items.get(i);
  }

  /** Bounds-safe link accessor; returns {@code null} instead of throwing. */
  public String getLink(int i) {
    GResults item = itemAt(i);
    return item == null ? null : item.link;
  }

  public String toString() {
    return String.format("%s", link);
  }
}