# MFiAdapter

[![Build Status](https://jenkins.yuneecresearch.com/job/MFiAdapter/badge/icon)](https://jenkins.yuneecresearch.com/job/MFiAdapter/)

This repo contains all the pieces needed to talk to the ST10C Remote Controller.

An example usage of these frameworks can be found in [YUNEEC/MFiExample](https://github.com/YUNEEC/MFiExample/).

## Frameworks

In an iOS app, the frameworks below need to be added to the "Embedded Binaries":

   - `BaseFramework`
   - `CocoaAsyncSocket`
   - `FFMpegDecoder`
   - `FFMpegDemuxer`
   - `FFMpegLowDelayDecoder`
   - `FFMpegLowDelayDemuxer`
   - `MediaBase`
   - `MFiAdapter`
   - `YuneecDataTransferManager`
   - `YuneecMFiDataTransfer`
   - `YuneecRemoteControllerSDK`
   - `YuneecWifiDataTransfer`

## Getting the frameworks

There are two ways to access these frameworks:

1. Manually downloading and extracting the zip file containing the frameworks from the [H520 update page](https://d3qzlqwby7grio.cloudfront.net/H520/index).

2. Using `carthage`, however this requires permission to the GitHub repositories of all these XCode projects.
   The `Cartfile` needs to contain:
   ```
   github "YUNEEC/MFiAdapter" "master"
   ```
