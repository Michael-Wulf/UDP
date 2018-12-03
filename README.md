# Bpod r0.5.1 PCB
Minor improvements compared to the original Bpod r0.5 release:
* Added bypass-capacitors to the VCC-inputs of all ICs
* Added GND polygon on top and bottom layer
* Rerouted the layout to reduce cross-talk between adjacent outputs ports

## Assembly instructions
Will be updted soon...  
For now see:  
https://sites.google.com/site/bpoddocumentation/assembling-bpod/instructions

## Bill of materials (BOM)
| Part Name | Description | Manufacturer | Name | Vendor | Part-Number |
| --- | --- | --- | --- | --- | --- |
| | Arduino Due | Arduino | Arduino Due | DigiKey | [1050-1049-ND](https://www.digikey.com/product-detail/en/arduino/A000062/1050-1049-ND "DigiKey 1050-1049-ND") |
| | DC/DC Converter | TDK Lambda | CC10-0512SF-E | DigiKey | [445-2433-ND](https://www.digikey.com/product-detail/en/CC10-0512SF-E/445-2433-ND "DigiKey 445-2433-ND") |
| `VALVE_REGISTER` | Power Shift Register | Texas Instruments | TPIC6A595 | DigiKey | [296-9007-5-ND](https://www.digikey.com/product-detail/en/texas-instruments/TPIC6A595NE/296-9007-5-ND "DigiKey 296-9007-5-ND") |
| `SYNC_REGISTER` | Shift Register | Texas Instruments, STMicro, NXP, … | 74HC595 | DigiKey | [296-1600-5-ND](https://www.digikey.com/product-detail/en/texas-instruments/SN74HC595N/296-1600-5-ND "DigiKey 296-1600-5-ND") |
| `5V_3V3_1/2/3` | 5V to 3.3V Converter (noninverting hex buffer) | Texas Instruments | CD4050BE | DigiKey | [296-2056-5-ND](https://www.digikey.com/product-detail/en/texas-instruments/CD4050BE/296-2056-5-ND "DigiKey 296-2056-5-ND") |
| `OPTOCOUPLER` | Opto-Coupler | Broadcom, Avago | HCPL-2231 | DigiKey | [516-1582-5-ND ](https://www.digikey.com/product-detail/en/broadcom-limited/HCPL-2231-000E/516-1582-5-ND "DigiKey 516-1582-5-ND ") |
| `Q3, Q4` | N-Channel MOSFET | ON Semi, STMicro, Microchip, NXP,… | 2N7000 | DigiKey | [2N7000FS-ND](https://www.digikey.com/product-detail/en/on-semiconductor/2N7000/2N7000FS-ND "DigiKey 2N7000FS-ND") |
| `LED` | RGB LED | Bivar Inc. | R50RGB-F-0160 | DigiKey | [492-1179-ND](https://www.digikey.com/product-detail/en/bivar-inc/R50RGB-F-0160/492-1179-ND "DigiKey 492-1179-ND") |
| `C1, C2, C3, C4, C5, C6` | 100 nF Bypass Capacitor (Ceramic) | Vishay, Kemet, AVX, … | 100 nF, 50 V, X7R | DigiKey | [BC5137-ND](https://www.digikey.com/product-detail/en/K104K10X7RF53L2/BC5137-ND "DigiKey BC5137-ND") |
| `R1` | 47 Ohm Current Limiting Common Cathode RGB LED | Stackpole, Yageo, Vishay, TE, … | 47 Ohm, 1/4 W, 1% | DigiKey | [BC4379CT-ND](https://www.digikey.com/product-detail/en/SFR2500004709FR500/BC4379CT-ND "DigiKey BC4379CT-ND") |
| `R2, R3` | 1 kOhm Current Limiting for Opto-Coupler | Stackpole, Yageo, Vishay, TE, … | 1 kOhm, 1/4 W, 1% | DigiKey | [RNF14FTD1K00CT-ND](https://www.digikey.com/product-detail/en/RNF14FTD1K00/RNF14FTD1K00CT-ND "DigiKey [RNF14FTD1K00CT-ND") |
| `R4, R5` | 10 kOhm Pull-Up BNC-Output | Stackpole, Yageo, Vishay, TE, … | 10 kOhm, 1/4 W, 1% | DigiKey | [RNF14FTD10K0CT-ND](https://www.digikey.com/product-detail/en/RNF14FTD10K0/RNF14FTD10K0CT-ND "DigiKey RNF14FTD10K0CT-ND") |
| | Socket DIP8 (OPTOCOUPLER) | On Shore, Assmann, TE, Amphenol, ... | DIP Socket 8 Pos | DigiKey | [ED3044-5-ND](https://www.digikey.com/product-detail/en/ED08DT/ED3044-5-ND "DigiKey ED3044-5-ND") |
| | Socket DIP16 (CD4050/74HC595) | On Shore, Assmann, TE, Amphenol, ... | DIP Socket 16 Pos | DigiKey | [ED3046-5-ND](https://www.digikey.com/product-detail/en/ED16DT/ED3046-5-ND "DigiKey ED3046-5-ND") |
| | Socket DIP20 (TPIC6A595) | On Shore, Assmann, TE, Amphenol, ... | DIP Socket 20 Pos | DigiKey | [ED3054-5-ND](https://www.digikey.com/product-detail/en/ED20DT/ED3054-5-ND "DigiKey ED3054-5-ND") |
| | Pinheader for Arduino Pins 0-21 & Analog (8-Pin) | Sparkfun | Stackable Header 8 Pin | Sparkfun | [PRT-09279](https://www.sparkfun.com/products/9279 "Sparkfun PRT-09279") |
| | Pinheader for Arduino Power Pins (6-Pin) | Sparkfun | Stackable Header 6 Pin | Sparkfun | [PRT-09280](https://www.sparkfun.com/products/9280 "Sparkfun PRT-09280") |
| | Pinheader for Arduino Pins 22-53 | Sullins, Amphenol, TE, … | Pinheader 36 Pos 0.1 spacing | DigiKey | [S2011EC-18-ND](https://www.digikey.com/product-detail/en/PRPC018DAAN-RC/S2011EC-18-ND "DigiKey S2011EC-18-ND") |
| | Header for Arduino ISP Pins| Sullins, Samtec, TE, … | Header (Female) 6 Pin | DigiKey | [S7106-ND](https://www.digikey.com/product-detail/en/sullins-connector-solutions/PPPC032LFBN-RC/S7106-ND "DigiKey S7106-ND") |
| `Ports` | RJ45 Ports | TE | Modular Jack 8P8C RJ45 | DigiKey | [A31442-ND](https://www.digikey.com/product-detail/en/5555164-1/A31442-ND "DigiKey A31442-ND") |
| `BNC` | BNC Ports | TE | BNC Jack 75 Ohm | DigiKey | [A97562-ND](https://www.digikey.com/product-detail/en/1-1634622-0/A97562-ND "DigiKey A97562-ND") |
| `Spring Terminal` | Spring Terminal for Wire I/Os | TE | Terminal Block 1-1986711-0 | DigiKey | [A104562-ND](https://www.digikey.com/product-detail/en/1-1986711-0/A104562-ND "DigiKey A104562-ND") |
| | Spacer for Arduino Due | Bivar Inc.  | Round Spacer Nylon 1/4" | DigiKey | [492-1074-ND](https://www.digikey.com/product-detail/en/9908-250/492-1074-ND "DigiKey 492-1074-ND") |
| | Spacer for Bpod PCB | Bivar Inc.  | Round Spacer Nylon 3/4" | DigiKey | [492-1081-ND](https://www.digikey.com/product-detail/en/9908-750/492-1081-ND "DigiKey 492-1081-ND") |
| | Screw for Arduino Due | B&F | Screw 4-40 Phillips, 0.625" thread length | DigiKey | [H348-ND](https://www.digikey.com/product-detail/en/b-f-fastener-supply/PMS-440-0063-PH/H348-ND "H348-ND") |
| | Screw for Bpod PCB | McMaster-Carr | Screw 4-40 Phillips, 1.125" thread length | McMaster-Carr | [91772A118](https://www.mcmaster.com/91772A118 "DigiKey 91772A118") |
| | Screws for Enclosure | B&F | Screw 4-40 Phillips, 0.5" thread length | DigiKey | [H346-ND](https://www.digikey.com/product-detail/en/b-f-fastener-supply/PMS-440-0050-PH/H346-ND "DigiKey H346-ND") |
| | Hex-Nuts| McMaster-Carr | Hex Nut 1/4" 4-40 | McMaster-Carr| [90480A005](https://www.mcmaster.com/90480A005 "DigiKey 90480A005") |
