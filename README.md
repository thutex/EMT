# EMT

For those who don't want an entire web-based server management
(also: free, which everyone loves)

## Getting Started

Just put the EMT files somewhere, i personally have them in /opt/EMT and symlinked to /usr/bin
(warning: there are still some hard-coded references to /opt/EMT!)

### Prerequisites

There are a few, like: the scripts have some expectations of where to find files,
i'll add them here when i find the time
tip: if you don't know bash or don't like risks, don't use this yet - there are quite a few places that are still hard-coded instead of in a config file, so it's not (yet) an out-of-the-box solution

```
-> you created all the directories/configurations that need to be used (might change in future revisions with an installer)
-> you know (somewhat) what you're doing (because at this stage, there is almost no error checking in the script)
-> more info will come here sometime in the future
```

## Usage

run EMT, the rest should be quite clear (using dialog) - but more instructions might be added to the dialog in the future.

## TODO

- put error checking in place (i.e.: dummy-proof the scripts)
- clean up code (i.e: make sure it does what its supposed to without any risks)
- add an installer (you know, just to be able to be completely lazy afterwards)


## Authors

* **Bjorn Peeters** - *Initial work* - [ThuTex](https://github.com/ThuTex)

## License

This project is licensed under the GNU GPLv3 License - see the [LICENSE.md](LICENSE.md) file for details
