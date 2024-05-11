import subprocess
import os
import time
import webbrowser

def close_media_player():
    subprocess.Popen(["taskkill", "/f", "/im", "wmplayer.exe"], shell=True)

def play_audio():
    subprocess.Popen(["start", "./_internal/like_a_surgeon.mp3"], shell=True)
    time.sleep(2)  # Adjust this delay as needed

def open_html():
    # Get the absolute path of welcome.html
    html_path = os.path.abspath("./_internal/welcome.html")
    # Open HTML file in a new instance of the default web browser in a new window
    webbrowser.open_new("file:///" + html_path)

def main():
    play_audio()
    open_html()


if __name__ == "__main__":
    main()
