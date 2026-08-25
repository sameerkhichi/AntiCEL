<p align="center">
  <img src="AntiCEL/Assets.xcassets/AppIcon.appiconset/AppIcon.png" alt="AntiCEL" width="120" />
</p>

<h1 align="center">AntiCEL</h1>

<p align="center"><em>Built by a detail-oriented enthusiast aiming to create a place to store, track, and document vehicle builds and maintenance.</em></p>

AntiCEL is an iOS garage for people who actually care about their cars. Park every vehicle in one place, keep the paper trail with the photos, and look back at what you’ve done without digging through texts, folders, and receipts.

Connect is there if you want the car talking back. It is optional. You do not need an adapter to use the rest of the app.

---

## The garage

Your vehicles sit in bays, each with its own photo, nickname, and mileage. Open a car and you get five rooms:

**Overview · History · Documents · Album · Connect**

Update mileage from the vehicle screen, the garage, Siri, or a Home Screen widget. Miles or kilometers, your call.

---

## Overview

The dashboard for that car.

- **Service reminders** by date, mileage, or whichever comes first. Mark one complete and AntiCEL writes a matching history entry for that part of the vehicle.
- **Notes** for the things that are not a service and not a history event — paint codes, tire sizes, the little details you always forget.
- **Shops** for the people you actually use: the mechanic, the tint shop, the tire place.
- **Quick info** so year, VIN, and odometer are never more than a tap away.

Reminders can ping you ahead of time, and again when the date or mileage hits.

---

## History

This is the build and service log.

Log maintenance, repairs, modifications, inspections, accidents, purchase, sale, or a simple note. Attach a photo, tag the area of the car, and keep the mileage with the work.

View it two ways:

- **On the car** — a 3D model with hotspots. Tap the engine, the brakes, the interior, and see only the work that belongs there.
- **As a list** — every entry in one place, if you just want to scroll.

Completed service reminders land here automatically. Faults you clear through Connect stay in history too, so the check-engine light is not the only record of what happened.

---

## Documents

Registration, insurance, a bill of sale, inspection paperwork — anything you would hate to lose. Add an expiry date and AntiCEL can remind you before it lapses.

---

## Album

A photo roll for that vehicle, grouped by month. Shoot from the camera or pull from your library. These are the shots you want sitting with the car, not buried in Camera Roll.

If storage is tight, Low Storage Mode can keep album photos linked to your library instead of copying them into the app.

---

## Connect

Plug in a Bluetooth OBD adapter and AntiCEL can ride along. Pair from the Connect screen, not from iOS Bluetooth Settings.

**What it can do**

- **Keep mileage honest.** If the car reports odometer over OBD, AntiCEL uses that. If it does not, distance is estimated from speed and time. Large jumps ask before they save, so a weird reading does not overwrite what you know is right.
- **Scan for faults.** Pull diagnostic codes, read what they mean, and keep a record. Scan on demand, or let a drive produce a summary when you park.
- **Watch the live numbers.** Fuel, coolant, and oil temperature while you are connected. Not every car reports oil temp.
- **Drive alerts after you stop.** Fill-up reminder, new faults from that trip, high coolant, high oil. They wait about ten minutes after the adapter goes quiet so a short stop does not fire one. If the adapter comes back, the reminder is cancelled.
- **Stay connected in the background.** Once paired, AntiCEL keeps looking for that adapter while you drive, including with the phone locked. Forget the adapter if you want that to stop.
- **Clear codes** when you understand why they are there. Clearing does not fix the fault. Cleared codes leave Connect and remain in History.

**What you need**

Connect is optional. AntiCEL is not sponsored, does not sell adapters, and the rest of the garage works without one.

The supported and tested device is the **Veepeak OBDCheck BLE+**. Most BLE ELM327 adapters (ones that say BLE, Bluetooth Low Energy, or iOS compatible) should connect. Classic Bluetooth dongles, Wi-Fi-only adapters, and dealer scanners are not supported.

Unplug the adapter for long storage or extreme cold. Leaving any dongle in the port for days is still a battery risk.

---

## Share a vehicle

Send a copy of a car to someone else who uses AntiCEL — a buyer, a shop, a friend building something similar. You choose what goes in the package: VIN, history, documents, album, reminders, notes, and shops. The original stays in your garage. Open the `.anticel` file on the other phone to import it.

---

## Around the rest of the phone

- **Odometer widget** on the Home Screen or Lock Screen. Check mileage, type a new reading, or add distance from the dash keys.
- **Siri shortcuts** to set mileage without opening the app.
- **Notifications** for upcoming service and expiring documents, on top of the drive alerts from Connect.
- **Look** that you can tune: separate accents for light and dark, from amber and Guards Red to cobalt and racing yellow.

---

AntiCEL is for the person who wants one honest record of a vehicle — what it is, what you have done to it, and what it is telling you when you let it talk.
