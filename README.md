<br />
<div align="center">

  <h3 align="center">Love2d Midi Visualizer</h3>

  <p align="center">
    Music Visualizer with love2d using Midi Files
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#getting-started">Getting Started</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

## About The Project

By using the midi files, firstly converting them into json files to make them
readable with lua. Then parsing the music data to play the corresponding notes with luamidi.dll.
Then using [the flocking simulation](http://www.red3d.com/cwr/boids/), The boids are triggered by the notes.

### Built With

[![LOVE](https://img.shields.io/badge/L%C3%96VE-11.4-EA316E.svg)](http://love2d.org/)

<!-- GETTING STARTED -->

## Getting Started

- First install [LÖVE](https://love2d.org/) if you haven't already.

- Then download [luamidi.dll_32](https://github.com/SiENcE/lovemidi/blob/master/tests/love2d/luamidi.dll) OR [luamidi.dll_64](https://github.com/SiENcE/lovemidi/blob/master/tests/love2d/luamidi.dll_64) _depending on the version of love you downloaded_ and place it in your Love2d folder _(typically C:\Program Files\LOVE)_ .

- Then find a midi song you wish to play. Check [bitmidi](https://bitmidi.com/) for free midi files.<br>
  Then you'll have to convert it to a json file using [this Converter](https://www.visipiano.com/midi-to-json-converter/).
  <br>
  I've provided an [example song](https://github.com/AhmedDawoud3/Love2d-Midi-Visualizer/blob/master/song.json) in the repo.

<!-- USAGE EXAMPLES -->

## USAGE

- ## Clone the project

```
git clone https://github.com/AhmedDawoud3/Love2d-Midi-Visualizer
cd Love2d-Midi-Visualizer/
```

---

- ## Run The Game
  You'll have to provide the json file as a command line argument as following: `love . [The Song File]`

```bash
love . song.json
```

Et voilà

<!-- CONTRIBUTING -->

## Contributing

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<!-- LICENSE -->

## License

Distributed under the MIT License. See [License](https://github.com/AhmedDawoud3/Love2d-Midi-Visualizer/blob/master/LICENSE) for more information.

<!-- CONTACT -->

## Contact

Your Name - [@AhmedDawoud314](https://twitter.com/AhmedDawoud314) - adawoud1000@hotmail.com

Project Link: [https://github.com/AhmedDawoud3/Love2d-Midi-Visualizer](https://github.com/AhmedDawoud3/Love2d-Midi-Visualizer)

