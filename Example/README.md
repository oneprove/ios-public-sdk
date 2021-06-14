# iOS Sample Project App for Authentication of the Valuable Items

## Introduction

Sample project that enables a single iOS developer to quickly build end-to-end solution for protecting valuable items such as Trading Cards, Coins, Stamps, Collectable banknotes, etc. Sample app code is adapted from published app, used and tested for years in diverse conditions and therefore represent a stable version for the Authentication usecase scenarios.

---

## Sample Project Application

### **Purpose**

Creating the application from scratch is a long process. Userflows, concept logic, usecase specific code (Augmented Reality navigation), edge cases, communication with backend, bug fixing etc. This project encapsulates all of this into coherent working product. A full feature app for authentication of the valuable physical items using Computer Vision algorithms.

### **Focus on business**

Sample App offers a plug and play solution, ready for integration into existing app, that saves development resources and therefore **unlock your focus on business opportunities** rather than tedious product development and engineering. App is integrated with Veracity Protocol API through ***iOS SDK*** for item authentication purposes (Item management and AI algorithms).

### **User Flows**

App authentication feature involves 2 main user flows, namely Protection and Verification of the item. UI view components of the sample app are derived from the app tested in a real-life production usage, therefore recommended as the best practice UX. UX plays a crucial role in a developing of the trust towards the innovative technology and its adoption. **Interface can be accommodated to specific branding or layout/user flow needs.**


---

# Steps to Start Using the App

- Make sure to have cocoapods installed
- Open terminal and cd into Example folder
- Run `pod install` in terminal
- Open `VeracitySample.xcworkspace`
- Replace the empty credentials with the credentials provided byt Veracity Protocol in ViewController.swift on lines 35, 36
- If you wish to run on real device you will need to change Signing Capabilities with your apple developer account
- Run the project
- On device allow your developer certificate if needed (Settings -> General -> Profiles & Device Management)

---

# Code Documentation

**Gitbook** - Details about architecture and requirements with code samples

[https://veracityprotocol.gitbook.io/api/veracity-sdk/ios-sdk](https://veracityprotocol.gitbook.io/api/veracity-sdk/ios-sdk)

---

# Technology

Veracity Protocol uses Computer Vision algorithms that utilizes unique material microstructure as a "fingerprint" of the item. To better understand which business use-cases are suitable based on the underlying  technology mechanism and its limitations read **Technology Primer** wiki:

[A Primer On Veracity Protocol Technology](https://www.notion.so/A-Primer-On-Veracity-Protocol-Technology-df6c2a33930343c0b5bfd5b8e47ad81c)

### **Technology Limitations - Consultation**

❗To better understand the conditions (material, light, product), under which the technology **guarantee the accuracy** for protection & verification of the item, [contact us to schedule the meet](mailto:hello@veracityprotocol.org) with the person from the product development team of Veracity Protocol.

### Keep in mind when using the app

❗Avoid poor light conditions! When taking photos in any part of user journey make sure that the light conditions are solid. The more controlled environment the better.