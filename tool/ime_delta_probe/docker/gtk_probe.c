/* Minimal GTK3 control: one GtkEntry, prints its text on every change.
 * Distinguishes "environment/ibus is broken" from "the Flutter embedder is
 * broken": if Hangul composes here but not in the Flutter probe, the break
 * is inside Flutter's Wayland text-input path. */
#include <gtk/gtk.h>

static void on_changed(GtkEditable *editable, gpointer user_data) {
  (void)user_data;
  g_print("text=%s\n", gtk_entry_get_text(GTK_ENTRY(editable)));
}

static void on_preedit(GtkEntry *entry, gchar *preedit, gpointer user_data) {
  (void)entry;
  (void)user_data;
  g_print("preedit=%s\n", preedit);
}

int main(int argc, char **argv) {
  gtk_init(&argc, &argv);
  GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(window), "gtk_probe");
  GtkWidget *entry = gtk_entry_new();
  g_signal_connect(entry, "changed", G_CALLBACK(on_changed), NULL);
  g_signal_connect(entry, "preedit-changed", G_CALLBACK(on_preedit), NULL);
  gtk_container_add(GTK_CONTAINER(window), entry);
  g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
  gtk_widget_show_all(window);
  gtk_widget_grab_focus(entry);
  gtk_main();
  return 0;
}
