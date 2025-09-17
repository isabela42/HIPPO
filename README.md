[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/isabela42/HIPPO">
    <!-- <img src="images/pipelineSimplels.png" alt="Logo" width=400>-->
  </a>

  <h3 align="center">HIPPO</h3>

  <p align="center">
    HiChIP Integration Pipeline for PBS Operations
  </p>
</p>

<!-- TABLE OF CONTENTS -->
<details open="open">
  <summary><h2 style="display: inline-block">Table of Contents</h2></summary>
  <ol>
    <li>
      <a href="#overview">Overview</a>
    </li>
    <li>
      <a href="#pipeline-prerequisites">Pipeline prerequisites</a>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#license">License</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->
## Overview

This repository contains the scripts used in our in-house RNAseq analysis pipeline that runs on a PBS cluster.

Each script file foccus on one part of the analysis, from file preparation and quality assessment to creating BED coordinate files for UCSC Browser visualisation and coordinate intersection.

* 010 Index building (1Bowtie)
* 020 Identify restriction fragments after digestion (1HiC-Pro)
* 030 Get chromosome sizes (1Awk)
* 040 Create HiChIP config files (1Bash)
* 050 Run HiC-Pro complete workflow (1HiC-Pro)
* 060 Construct features (1HiCDC+)
* 070 20kb range quality control (1HiCDC+)
* 080 5kb range interaction calls (1HiCDC+)
* 090 Create UCSC browser tracks (1 txt.gz, 2 pgl)
* 100 Intersect calls with BED coordinates (1pgltools)

<!-- GETTING STARTED -->
## Pipeline Prerequisites

To get a local copy up and running, make sure you have each script file prerequisites instaled and up to date.

<!-- USAGE EXAMPLES -->
## Usage

Each script can be executed in a PBS cluster by using the following command line:
 
```sh
bash script-name.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"
```

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


<!-- ACKNOWLEDGEMENTS
## Acknowledgements

* []()
* []()
* []() -->


<!-- CONTACT -->
## Contact

Isabela Almeida - mb.isabela42@gmail.com

Project Link: [https://github.com/isabela42/HIPPO](https://github.com/isabela42/HIPPO)

<!-- LICENSE -->
## License

Distributed under the MIT License. See [LICENSE][license-url] for more information.


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/isabela42/HIPPO.svg?style=for-the-badge
[contributors-url]: https://github.com/isabela42/HIPPO/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/isabela42/HIPPO.svg?style=for-the-badge
[forks-url]: https://github.com/isabela42/HIPPO/network/members
[stars-shield]: https://img.shields.io/github/stars/isabela42/HIPPO.svg?style=for-the-badge
[stars-url]: https://github.com/isabela42/HIPPO/stargazers
[issues-shield]: https://img.shields.io/github/issues/isabela42/HIPPO.svg?style=for-the-badge
[issues-url]: https://github.com/isabela42/HIPPO/issues
[license-shield]: https://img.shields.io/github/license/isabela42/HIPPO.svg?style=for-the-badge
[license-url]: https://github.com/isabela42/HIPPO/blob/master/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/isabela42/
