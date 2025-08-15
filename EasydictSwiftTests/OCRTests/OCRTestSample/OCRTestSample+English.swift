//
//  OCRTestSampleEnglish.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2025/7/27.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/// English OCR test samples
extension OCRTestSample {
    // MARK: - English Text Cases

    static let englishCases: [OCRTestSample] = [
        .enText1, .enText2, .enText3, .enText4, .enText5,
        .enTextBitcoin, .enTextReddit, .enTextLetter338,
        .enTextList1, .enTextList2, .enTextList3,
        .enTextTwoColumns1, .enTextTwoColumns2,
        .enPaper1, .enPaper2, .enPaper3, .enPaper4, .enPaper5, .enPaper6, .enPaper7,
        .enPaper8, .enPaper9, .enPaper10, .enPaper11, .enPaper12, .enPaper13,
        .enPoetry8,
    ]

    // MARK: - English Expected Results

    /// Expected results for English OCR test samples
    static let englishExpectedResults: [OCRTestSample: String] = [
        // ocr english text
        enText1: """
        4 cars leave Haifa together and arrive in Aviv after two hours. Explain briefly how long would it take for 8 cars?

        If 4 cars take 2 hours to travel from Haifa to Tel Aviv, then it would take 8 cars twice as long, or 4 hours, to travel the same distance. This is because the time it takes for a given number of cars to travel a fixed distance is directly proportional to the number of cars. Therefore, if the number of cars is doubled, the time it takes to travel the same distance will also be doubled.
        """,

        enText2: """
        HEY GAMERS!

        Today, Unity (the engine we use to make our games) announced that they'll soon be taking a fee from developers for every copy of the game installed over a certain threshold - regardless of how that copy was obtained.

        Guess who has a somewhat highly anticipated game coming to Xbox Game Pass in 2024? That's right, it's us and a lot of other developers.

        That means Another Crab's Treasure will be free to install for the 25 million Game Pass subscribers. If a fraction of those users download our game, Unity could take a fee that puts an enormous dent in our income and threatens the sustainability of our business.

        And that's before we even think about sales on other platforms, or pirated installs of our game, or even multiple installs by the same user! !!

        This decision puts us and countless other studios in a position where we might not be able to justify using Unity for our future titles. If these changes aren't rolled back, we'll be heavily considering abandoning our wealth of Unity expertise we've accumulated over the years and starting from scratch in a new engine. Which is really something we'd rather not do.

        On behalf of the dev community, we're calling on Unity to reverse the latest in a string of shortsighted decisions that seem to prioritize shareholders over their product's actual users.

        I fucking hate it here.

        -Aggro Crab
        """,
        enText3: """
        We are writing to notify you that, pursuant to orders by the Chinese government, your app will be made unavailable on the China App Store because it includes content that is illegal in China. As you may know, the government has been tightening regulations associated with deep synthesis technologies (DST) and generative Al services, including ChatGPT. DST must fulfill permitting requirements to operate in China, including securing a license from the Ministry of Industry and Information Technology (MIIT). Based on our review, your app is associated with ChatGPT, which does not have requisite permits to operate in China.
        """,
        enText4: """
        Vision

        Apply computer vision algorithms to perform a variety of tasks on input images and videos.

        Overview

        The Vision framework combines machine learning technologies and Swift's concurrency features to perform computer vision tasks in your app. Use the Vision framework to analyze images for a variety of purposes:
        · Tracking human and animal body poses or the trajectory of an object
        · Recognizing text in 18 different languages
        · Detecting faces and face landmarks, such as eyes, nose, and mouth
        · Performing hand tracking to enable new device interactions
        · Calculating an aesthetics score to determine how memorable a photo is

        To begin using the framework, you create a request for the type of analysis you want to do. Each request conforms to the VisionRequest protocol. You then perform the request to get an observation object - or an array of observations - with the analysis details for the request. There are more than 25 requests available to choose from. Vision also allows the use of custom Core ML models for tasks like classification or object detection.

        Note

        Starting in iOS 18.0, the Vision framework provides a new Swift-only API. See Original Objective-C and Swift API to view the original API.

        Open in Developer Documentation
        """,
        enText5: """
        "The best recent book on China, on China and America, and, arguably, the best book of the year flat out. " -TYLER COWEN

        China's Quest
        to Engineer
        the Future

        BREAKNECK

        DAN WANG
        """,

        enTextBitcoin: """
        Bitcoin: A Peer-to-Peer Electronic Cash System

        Satoshi Nakamoto
        satoshin@gmx.com
        www.bitcoin.org

        Abstract. A purely peer-to-peer version of electronic cash would allow online payments to be sent directly from one party to another without going through a financial institution. Digital signatures provide part of the solution, but the main enefits are lost if a trusted third party is still required to prevent double-spending Ve propose a solution to the double-spending problem using a peer-to-peer network The network timestamps transactions by hashing them into an ongoing chain of hash-based proof-of-work, forming a record that cannot be changed without redoing the proof-of-work. The longest chain not only serves as proof of the sequence of events witnessed, but proof that it came from the largest pool of CPU power. As long as a majority of CPU power is controlled by nodes that are not cooperating to attack the network, they'll generate the longest chain and outpace attackers. The network itself requires minimal structure. Messages are broadcast on a best effort basis, and nodes can leave and rejoin the network at will, accepting the longest proof-of-work chain as proof of what happened while they were gone.

        1. Introduction

        Commerce on the Internet has come to rely almost exclusively on financial institutions serving as trusted third parties to process electronic payments. While the system works well enough for most transactions, it still suffers from the inherent weaknesses of the trust based model. Completely non-reversible transactions are not really possible, since financial institutions cannot avoid mediating disputes. The cost of mediation increases transaction costs, limiting the minimum practical transaction size and cutting off the possibility for small casual transactions, and there is a broader cost in the loss of ability to make non-reversible payments for nonreversible services. With the possibility of reversal, the need for trust spreads. Merchants must be wary of their customers, hassling them for more information than they would otherwise need. A certain percentage of fraud is accepted as unavoidable. These costs and payment uncertainties can be avoided in person by using physical currency, but no mechanism exists to make payments over a communications channel without a trusted party.

        What is needed is an electronic payment system based on cryptographic proof instead of trust, allowing any two willing parties to transact directly with each other without the need for a trusted third party. Transactions that are computationally impractical to reverse would protect sellers from fraud, and routine escrow mechanisms could easily be implemented to protect buyers. In this paper, we propose a solution to the double-spending problem using a peer-to-peer distributed timestamp server to generate computational proof of the chronological order of transactions. The system is secure as long as honest nodes collectively control more CPU power than any cooperating group of attacker nodes.
        """,

        enTextReddit: """
        I'm in love with this fucking language

        Am I allowed to rant here?

        I tried this language out a few years back and was like "what the fuck is this garbage? " and didn't look at it since then (until a week ago).

        Thing is, I'm a self taught web developer. Professionally I've only really dealt with high level languages like Javascript, Ruby, PHP, etc, and on top of that, mostly using frameworks. On my spare time I've been building a game in C++ and so I've essentially forced myself to learn something more computer-sciency.

        Over the last year or so I've been really deep-diving, learning C++, learning C, learning Crystal Lang (it's a lot like Ruby syntax). I've gained a real interest in actual CS. For the last week I've been trying out Rust and...

        Holy fuck. It's taken me a bit to start seeing the light but my god is it there.

        I have to say to all of you, you're doing a tremendous job, Rust is straight up the future, I can feel it. Fuck the rest, all my homies hate the rest. I built a shitty ass version of Next.JS in a
        """,

        enTextList1: """
        I understand all of the rules above and am capable of following them.

        The rules are as follows:

        1. I am a girl with severe depression and severe anxiety.
        2. I am the second daughter in my family, 10 years younger than my older sister and 2 years younger than my younger brother.
        3. My parents always say I am 3*, and if it weren't for my cuteness when I was young, they would have drowned me or given me away.
        4. I am very introverted and have few friends.
        """,

        enTextList2: """
        What's Changed

        · fix: change Volcano response Extra type from String to Dictionary by @tisfeng in #863
        · feat: support auto detection for classical Chinese (Enabled in beta mode) by @tisfeng in #872
        · fix: activate app after taking screenshot by @tisfeng in #873
        · feat: add enableDarkOverlay option, default to false by @tisfeng in #874
        · feat: add GitHub Models service by @tisfeng in #877
        · feat: add Groq service by @tisfeng in #878
        · fix: restore wrong last application when switching applications by workspace by @tisfeng in #879

        Full Changelog: 2.13.0...2.14.1
        """,

        enTextList3: """
        What's Changed

        · fix: change Volcano response Extra type from String to Dictionary by @tisfeng in #863
        · feat: support auto detection for classical Chinese (Enabled in beta mode) by @tisfeng in #872
        · fix: activate app after taking screenshot by @tisfeng in #873
        · feat: add enableDarkOverlay option, default to false by @tisfeng in #874
        · feat: add GitHub Models service by @tisfeng in #877
        · feat: add Groq service by @tisfeng in #878
        · fix: restore wrong last application when switching applications by workspace by @tisteng in #879

        Full Changelog: 2.13.0...2.14.1
        """,

        enTextLetter338: """
        It is my turn to sue and be sued. I wrote in The Second Sex about whores and prostitutes, and among names of elegant whores of 1900, I gave the name of Cléo de Mérode. Last Sunday. Somebody spoke at the radio, pretending to be me. read this part of the book, and insulted Cléo de Mérode. So now I learn in newspapers and a personal letter that she sues me. And I sue the radio for having used my name. I send you a nice picture of the woman and myself. In fact, I though she was dead since long, which would have made things much easier.

        Toulouse has got through a desintoxication cure; she is quite different: fair, pink, soft, smiling, dressed in a long white night-gown, looking healthy and sweet. But she spoke for an hour and a half without stopping one second, which means she was not quite normal. She was interesting because she described the way she has been nursed; it seems a terrible thing. It lasted six days. The first they gave her a mild typhoidic fever - a real shock-then every day they doped her in many different ways, pushing long thick needles in her poor flesh and veins, oily things had to go to her brain and give it some grease, for the wine had eaten the grease up, they say. She had to keep a nurse night and day, because she wanted to jump through the window, she had such anguish from lack of wine. Now it seems her brain is little too greasy, that is why she speaks so much.

        Yours certainly is not. What a brute, not to send a short wire when I ask to you! I very often wait patiently for letters, but this time a letter was surely lost; you never made me wait for weeks, you used to be kinder than that until now. Shall I think you unkind rather than dead? Yea, now I shall, ugly muddy thing. Don't forget anyway to send next letters to the right places: Algiers, Hotel Saint Georges until i1th or 12th March, Gardhaia, Hotel Transatlantique, until 24th March.

        I cannot help loving you in spite of all. Enjoy yourself, when it is still time to, for within a few months. I'll give you a hard life; I'll punish you with all kinds of tricks. And if you are really too bad, I'll send to you Cléo de Mérode. Anyway, today I kiss you with my own mouth.

        Your own Simone

        p.s. I bought two glass-swords for my home. Very beautiful.

        338
        """,

        enTextTwoColumns1: """
        A Security Assessment of HTTP/2 Usage in 5G Service Based Architecture

        Nathalie Wehbe, Hyame Assem Alameddine, Makan Pourzandi, Elias Bou-Harb, and Chadi Assi

        Abstract-Fifth Generation (5G) networks are designed to bring enhanced network operational efficiencies to serve a wide range of emerging services. Towards this purpose, 5G adopts a Service Based Architecture (SBA) that features web-based technologies such as the Hypertext Transfer Protocol version 2 (HTTP/2) used for signalling and Application Programming Interfaces (APIs) for service delivery. Several works in the literature reported that the shift towards the aforementioned technologies brings potential cybersecurity challenges to the 5G network. In this article, we discuss different security features introduced by 5G SBA and explore these security challenges and their solutions in this new architecture. We carefully examine HTTP/2 features, standard and custom headers and discuss their security implications in 5G SBA. We comment on the applicability of some known HTTP/2 attacks in 5G SBA in light of the standardized APIs and discuss the security opportunities and research directions brought by this protocol and its related technologies.

        Index Terms-5G security, HTTP/2, Service Based Architecture, Application programming interface, OAuth 2.0

        I. INTRODUCTION

        Tie, marface in, e. etica ding stieg en Quality of 1 HE emergence of new vertical industries (e.g. , automoService (QoS) requirements (e.g. , ultra-low latency, high reliability, etc. ) pushed mobile network operators to revolutionize their telecommunication networks to support these new use cases [1], [2]. As a result, Fifth Generation (5G) networks have emerged, mainly adding a new radio access technology and moving from legacy hardware equipment to a complete virtualized new Service Based Architecture (SBA).

        The 5G SBA follows a cloud-native deployment and leverages virtualization technologies for the implementation of its Network Functions (NFs), thus enabling better scalability, flexibility and service management [2]. 5G relies on a standardized set of REpresentational State Transfer (RESTful) Application Programming Interfaces (APIs) combined with web-based technologies including the Transport Control Protocol (TCP) /Transport Layer Security (TLS) /Hypertext Transfer Protocol version 2 (HTTP/2) /JavaScript Object Notation (JSON) protocol suit for the communication between its NFs [3]. The use of virtualization technologies for the provisioning and automated management of NFs in the cloud-native deployment adopted for 5G networks, along with APIs and HTTP/2 serves the security-by-design principle that 5G SBA follows [2].

        In fact, the 5G SBA introduces new security features to enable resilient and reliable experience for 5G users. These

        Nathalie Wehbe and Chadi Assi are with the Concordia University, Hyame Assem Alameddine and Makan Pourzandi are with Ericsson Research, and Elias Bou-Harb is with the University of Texas at San Antonio

        features include network function registration, discovery and authorization, as well as the protection of the Service-Based Interfaces (SBI) [4]. They are enforced using the harmonized HTTP/2 protocol, employed for signalling between the 5G NFs. The HTTP/2 protocol offers new security opportunities through the introduced 3rd Generation Partnership Project (3GPP) custom HTTP headers as well as through its features ranging from server push capability, stream multiplexing and header compression among others [3], [5], [6].

        Although 5G SBA was designed with security in mind, it is of utmost importance to discuss and explore the new security challenges that are introduced in this architecture and its enabling technologies and protocols. Cybersercurity implications of web-based technologies on 5G SBA needs more attention. In fact, [3] presents some HTTP/2 attacks exploiting its features without a thorough discussion on their implications on 5G SBA; while other works [1], [7], [8] only focus on the vulnerabilities brought by virtualization technologies.

        Motivated by the fact that HTTP/2, APIs and JSON are well known to attackers, in this article, we provide a thorough discussion on the possible threats they introduce to 5G SBA with a focus on HTTP/2. First, we introduce 5G SBA with a close attention to the security associated with its NF services and their APIs. Then, we discuss the use of HTTP/2 in 5G SBA for fulfilling the need for reduced latency and communication overhead through its features that we expose. We assess the security implications of these features in 5G SBA and complement them by a discussion on the HTTP/2 standard and custom headers used for hardening 5G SBA security. Finally, we conclude with some security challenges and opportunities.

        II. 5G SERVICE BASED ARCHITECTURE (SBA)

        A. Overview

        5G networks revolutionized the telecommunication architecture by adopting a cloud-native, service-driven deployment promoting enhanced network operational efficiencies. The 5G SBA (Figure 1) enables a granular design and delivery of 5G network functionality through a decoupling of User Plane (UP) and Control Plane (CP), hence, providing independent scalability and flexible deployments [2], [9]. The UP and CP consist of multiple interconnected NFs, each providing a set of "services". Examples of such services include service registration, authorization and discovery [9]. The 5G CP is defined by a SBA. The interactions between the CP NFs are enabled by a service-based representation in which the SBIs can be easily extended without the need to introduce new reference points.
        """,

        enTextTwoColumns2: """
        C. Stream Dependency and Prioritization

        HTTP/2 carries a dependency-based prioritization feature that allows a client to assign a priority for each stream through a PRIORITY frame. Stream priority determines the order at which the client wants its streams to be processed [5]. A client can also specify dependency between streams that will be expressed in a dependency tree at the server. It can assign weights to dependent streams to dictate to the server the relative proportion of available resources that it has to allocate them [5]. The dependency-based prioritization feature was introduced with the intention of improving user experience. However, since no limit was set in RFC 7540 [5] on the size of the dependency tree, a NFp which naively trusts a NFc may be deceived to build a dependency tree that will consume its memory and CPU, thus causing a DoS on the NFp [3], [13]. The exploitation of this feature can be partially limited in 5G SBA by configuring the size of dependency tree at NFp for each TCP connection.

        D. Header Compression

        HTTP/2 introduces header compression through the HPACK protocol to reduce the request size by eliminating redundant header fields across multiplexed streams, which leads to lower bandwidth utilization [5]. HTTP/2 request and response header metadata are compressed using HPACK through: (1) encoding the transmitted header fields to reduce their individual transfer size; (2) maintaining an HPACK static table that holds a predefined static list of headers; (3) updating and maintaining an HPACK dynamic table that holds a dynamic list of headers [5]. It is used as a cache for each connection direction separately. The sender can signal to the receiver what values to insert in the dynamic table, hence, it can refer to their locations in subsequent streams. The size of the dynamic table is restricted to limit the memory requirement on the decoder side, however, the size of the header value field inside this table is not constrained [5], [13]. The lack of restriction on the size of the header value creates a vulnerability that can be exploited to launch an HPACK Bomb attack [13]. An attacker can generate a first stream with a large header (i.e. , of size equal to the dynamic table of its peer), then open new streams over the same connection that reference the same header. Decompressing the large header for each subsequent stream causes memory exhaustion, and hence a DoS on the server [13]. Limiting the header value in the dynamic table can potentially prevent the HPACK Bomb attack.

        E. Server Push

        The server push uses the PUSH_PROMISE frame to enable the server to send inline resources to the client without an explicit request for each resource [5]. This feature improves the client's experience by reducing the load time and workload, however, it places the burden on the server. The server push feature, combined with the multiplexing feature can be misused to launch a Distributed Denial of Service (DDoS) attack against an HTTP/2 server. A malicious client can force a server to serve a high number of simultaneous requests, each of which has multiple associated inline resources that the server needs to push [14]. This leads to a flooding attack which affects the server egress bandwidth and nearby routers, thus resulting in a DoS attack at the network layer as well [14]. The server push feature may not always be advantageous as it can use an excess of bandwidth to push unneeded assets. Mobile operators have to carefully assess the need for enabling this feature in their 5G networks as bandwidth and connection stability are crucial to meet the QoS requirements of their services.

        F. Discussion

        5G networks implement tighter security than the general web which reduces the likelihood of HTTP/2 attacks (Table I). Nonetheless, we believe that some of these HTTP/2 attacks are likely to apply to SG networks as they can be exploited by attackers through vulnerabilities related to virtualization technologies [7]. In fact, the move of mobile network operators to the public cloud increases the attack surface through virtualization vulnerabilities (e.g. , CVE-2016-5195, CVE-2019-5736). Similarly, virtualization vulnerabilities and misconfiguration can be exploited by attackers to breach the isolation between 5G network slices through for example a shared NF [15]. In such a scenario, HTTP/2 attacks on the shared NF from one slice can impact the functionality of the other slice. Further, HTTP/2 attacks can be initiated from malicious roaming partner and remain undetected by the filtering techniques at the SEPP [10]. Although they take a new form in HTTP/2, HTTP/2 multiplexing and slow-read attacks common in the Internet, may occur now in 5G networks. In contrast, we envision that stream dependency and prioritization based attacks along with server push and HPACK bomb attacks are less likely to happen in 5G networks as they are highly related to the mobile operators implementation and configuration. For instance, an operator may choose to disable server push functionality, thus preventing its related attack. To the best of our knowledge, the usage of server push has been left by 3GPP to the mobile operator choice. Finally, with the risk of misconfiguration of HTTP/2 settings and its related attacks, intelligent anomaly detection solutions that can detect HTTP/2 attacks to enable automated mitigation measures are needed.

        IV. IMPLICATIONS OF HTTP/2 STANDARD AND CUSTOM HEADERS ON 5G SBA

        HTTP/2 message header is composed of multiple standard and custom header fields that we elucidate and discuss their role in 5G SBA security.

        A. Standard HTTP/2 Headers
        The standard HTTP/2 header fields are used in both requests and responses. The request sent to the HTTP/2 server includes a list of header fields that identify the client. Figure 2 includes some of these standard headers: accept-encoding specifies the used data encoding; accept determines the content type the client is able to handle; authority defines the Fully Qualified Domain Name (FQDN) or IP address of the target Uniform
        """,

        // ocr english paper 1-14
        enPaper1: """
        Abstract-Fifth Generation (5G) networks are designed to bring enhanced network operational efficiencies to serve a wide range of emerging services. Towards this purpose, 5G adopts a Service Based Architecture (SBA) that features web-based technologies such as the Hypertext Transfer Protocol version 2 (HTTP/2) used for signalling and Application Programming Interfaces (APIs) for service delivery. Several works in the literature reported that the shift towards the aforementioned technologies brings potential cybersecurity challenges to the 5G network. In this article, we discuss different security features introduced by 5G SBA and explore these security challenges and their solutions in this new architecture. We carefully examine HTTP/2 features, standard and custom headers and discuss their security implications in 5G SBA. We comment on the applicability of some known HTTP/2 attacks in 5G SBA in light of the standardized APIs and discuss the security opportunities and research directions brought by this protocol and its related technologies.

        Index Terms-5G security, HTTP/2, Service Based Architecture, Application programming interface, Auth 2.0

        I. INTRODUCTION

        Tie, mariac ring, ex. tian ding stig ene Quality of 'HE emergence of new vertical industries (e.g. , automoService (QoS) requirements (e.g. , ultra-low latency, high reliability, etc. ) pushed mobile network operators to revolutionize their telecommunication networks to support these new use cases [1], [2]. As a result, Fifth Generation (5G) networks have emerged, mainly adding a new radio access technology and moving from legacy hardware equipment to a complete virtualized new Service Based Architecture (SBA).

        The 5G SBA follows a cloud-native deployment and leverages virtualization technologies for the implementation of its Network Functions (NFs), thus enabling better scalability, flexibility and service management [2]. 5G relies on a standardized set of REpresentational State Transfer (RESTful) Application Programming Interfaces (APls) combined with web-based technologies including the Transport Control Protocol (TCP) /Transport Layer Security (TLS) /Hypertext Transfer Protocol version 2 (HTTP/2) /JavaScript Object Notation (JSON) protocol suit for the communication between its NFs [3]. The use of virtualization technologies for the provisioning and automated management of NFs in the cloud-native deployment adopted for 5G networks, along with APIs and HTTP/2 serves the security-by-design principle that 5G SBA follows [2].

        In fact, the 5G SBA introduces new security features to enable resilient and reliable experience for 5G users. These

        Nathalie Wehbe and Chadi Assi are with the Concordia University, Hyame Assem Alameddine and Makan Pourzandi are with Ericsson Research, and Elias Bou-Harb is with the University of Texas at San Antonio
        """,

        enPaper2: """
        features include network function registration, discovery and authorization, as well as the protection of the Service-Based Interfaces (SBI) [4]. They are enforced using the harmonized HTTP/2 protocol, employed for signalling between the 5G NFs. The HTTP/2 protocol offers new security opportunities through the introduced 3rd Generation Partnership Project (3GPP) custom HTTP headers as well as through its features ranging from server push capability, stream multiplexing and header compression among others [3], [5], [6].

        Although 5G SBA was designed with security in mind, it is of utmost importance to discuss and explore the new security challenges that are introduced in this architecture and its enabling technologies and protocols. Cybersercurity implications of web-based technologies on 5G SBA needs more attention. In fact, [3] presents some HTTP/2 attacks exploiting its features without a thorough discussion on their implications on 5G SBA; while other works [1], [7], [8] only focus on the vulnerabilities brought by virtualization technologies.

        Motivated by the fact that HTTP/2, APls and JSON are well known to attackers, in this article, we provide a thorough discussion on the possible threats they introduce to 5G SBA with a focus on HTTP/2. First, we introduce SG SBA with a close attention to the security associated with its NF services and their APIs. Then, we discuss the use of HTTP/2 in 5G SBA for fulfilling the need for reduced latency and communication overhead through its features that we expose. We assess the security implications of these features in SG SBA and complement them by a discussion on the HTTP/2 standard and custom headers used for hardening 5G SBA security. Finally, we conclude with some security challenges and opportunities.

        I1. 5G SERVICE BASED ARCHITECTURE (SBA)

        A. Overview

        5G networks revolutionized the telecommunication architecture by adopting a cloud-native, service-driven deployment promoting enhanced network operational efficiencies. The 5G SBA (Figure 1) enables a granular design and delivery of 5G network functionality through a decoupling of User Plane (UP) and Control Plane (CP), hence, providing independent scalability and flexible deployments [2], [9]. The UP and CP consist of multiple interconnected NFs, each providing a set of "services". Examples of such services include service registration, authorization and discovery [9]. The SG CP is defined by a SBA. The interactions between the CP NFs are enabled by a service-based representation in which the SBIs can be easily extended without the need to introduce new reference points.
        """,

        enPaper3: """
        To enable the communication between the 5G SBA NFs (also referred to as "5G signalling"), the 3GPP selected the HTTP/2 protocol with JSON as the application layer serialization protocol, which runs over TCP at the transport layer [6]. For added security, the NFs shall support TLS 1.2 and TLS 1.3 [6], [8]. In addition, Restful API is used to invoke 5G services [9J ·

        B. HTTP/2 as Signalling Protocol for SG

        Multiple criteria were considered for selecting HTTP/2 as the signalling protocol for G. Despite supporting a large number of transactions per service and responding to low-latency requirements [5], [9], HTTP/2 enables multiple requests and responses over the same TCP connection between a client and a server, hence, supporting bidirectional and reliable communication [5]. This connection at the application-layer running on top of TCP is also known as HTTP/2 connection. When used in 5G SBA, one NF acts as NF Service Consumer (NFc), authorized to access a service of another NF which as is known as NF Service Producer (NFp). As such, HTTP/2 responds to SBIs requirements which include a RequestResponse in which a request for a service is issued by a NFc and a response is provided by a NFp; or Subscribe-Notify in which a NFc subscribes to a certain event of the NFp where the latter notifies the NFc upon the occurrence of the event [2].

        HTTP/2 introduces the notion of a stream, which corresponds to an HTTP request/response exchange. An HTTP/2 message is represented by either a request or a response. HTTP/2 messages are composed of HTTP/2 frames. Thus, a stream can be defined as a bidirectional flow of frames [5]. An HTTP/2 frame represents the basic HTTP/2 data unit (i.e. , smallest unit of communication within an HTTP/2 connection) with binary encoding. A frame can be of different types from
        """,

        enPaper4: """
        which we mention: (1) HEADERS frame which is used to open a stream and carries different header fields in the form of key-value pairs; (2) DATA frame carries HTTP request or response payload; (3) SETTINGS frame is used by both client and server to convey configuration parameters that affect their communication (5].

        C. SG SBA Signalling

        Signalling through direct communication between 5G NFs is enabled by HTTP/2 while being facilitated by the Network Repository Function (NRF) (Figure 1). Signalling allows NFs to consume services provided by their peers. In fact, a NFp will first register itself to the NRF. This enables the NRF to maintain a NF profile that includes the available NF instances and their services. A NFc can then discover the available NF instances and services by consulting the NRF. Once discovered, a NFc can directly consume authorized services through APIs exposed by a NFp [2]. These APls are standardized by 3GPP and can be either Request-Response or Subscribe-Notify [2].

        Signalling through indirect communication between the NFs consumers and producers is also possible through the Service Communication Proxy (SCP) NF (Figure 1) [6]. The SCP can route the requests and responses of service consumers and producers respectively, and offload the service registration and discovery requests to the NRF. Note that the SCP also provides load balancing, overload handling, traffic prioritization and message manipulation functionalities [6], [11].

        D. SG SBA Security

        SG SBA leverages cloud-native principles where NFs are created and destroyed dynamically and communicate through a SBl message bus using different APIs. These NFs should be authenticated and their communication needs to be protected to
        """,

        enPaper5: """
        prevent unauthorized access to their services. 3GPP identified two main security mechanisms:

        1) Mutual authentication and transport security: They are enforced through TLS between SBA NEs and between NFNRF during service discovery and registration to mitigate against message spoofing, tampering, repudiation and information disclosure [4], [8].

        2) Authorization of the requests: Access authorization of NFcs to services provided by NFps prevents privilege escalation. It follows a token-based authorization through the NRF using Auth 2.0 [4], [12]. OAuth 2.0 is an authorization framework that enables a third-party application to obtain limited access to an HTTP service on its behalf or on behalf of a resource owner [12]. In 5G SBA, an access token to a certain service is generated by the NRF (OAuth 2.0 authorization server) following a request of a NFc (i.e. , OAuth 2.0 client) to access a service of a NFp (i.e. , OAuth 2.0 resource server) [4]. The token is granted based on authorization rules which can be provided by the NFp during its registration at the NRF and after the mutual authentication between the NRF and the NFc (using TLS) [8].

        Authorization and authentication are applied in non-roaming and in roaming scenarios. Nonetheless, to better protect the 5G network from unauthorized access and attacks that can be performed by outsiders (e.g. , roaming partners, etc. ), a Security Edge Protection Proxy (SEPP) (Figure 1) has been introduced. SEPP acts as a security gateway on the interconnections between roaming partners. It provides application-layer security between NEs associated with roaming partners to enable their secure communication. SEPP functionalities include traffic filtering, end-to-end authentication, confidentiality and integrity protection via signatures and encryption of HTTP/2 messages. SEPP is also responsible of key management mechanisms used to perform the security capability procedures. Finally, the SEPP offers topology hiding capability along with prevention of bidding down attacks [4].

        III. IMPLICATIONS OF HTTP/2 FEATURES ON 5G SBA

        HTTP/2 introduces multiple features that we explore hereafter and discuss the security impact of their possible exploitation by attackers in 5G SBA.
        """,

        enPaper6: """
        A. Streams Multiplexing

        HTTP/2 streams multiplexing feature allows carrying multiple streams over a single TCP connection [5], thus improving services' latency. In fact, an HTTP/2 client/server can limit the maximum number of concurrent streams over a single TCP connection with its peers using the HTTP/2 SETTINGS_MAX_CONCURRENT_ STREAMS setting. While IETF recommends a minimum value of 100 streams for this setting to benefit from stream multiplexing feature, it does not provide any recommendations on its upper limit which can go up to 2, 147, 483, 647 streams [5]. This allows attackers to exploit stream multiplexing feature through sending as many as 2, 147, 483, 647 streams of computationally expensive requests (i.e. , APIs) towards the NFp and replicate it over multiple TCP connections to scale the attack and cause a Denial of Service (DoS) [13]. Hence, network operators should carefully configure the SETTINGS_MAX_CONCURRENT_STREAMS for their 5G NFs to limit such attack.

        B. Flow Control

        The flow control feature is introduced to prevent streams on the same TCP connection from interfering with each others [5]. Flow control determines the size of the data the sender is permitted to send to the receiver using many parameters such as the WINDOW UPDATE frame, and the SETTINGS frame [5]. The WINDOW UPDATE frame is used by the receiver to inform the sender how much data it is willing to receive on each stream [5]. The flexibility provided by this feature can be misused by a malicious receiver (i.e. , NFc in 5G) to influence the streams processing at the NFp into intensive resource consumption, thus causing a slow-read DoS attack on the NFp [3]. In fact, in such attack, a NFc imposes very small data transmission using the WINDOW_UPDATE frame on the NFp, thus keeping the NFp resources busy to complete its request. However, a possible preventive measure that can be taken in 5G networks, is to set a processing timeout limit for requests on each NFp based on the vertical industry the NFp is serving.
        """,

        enPaper7: """
        C. Stream Dependency and Prioritization

        HTTP/2 carries a dependency-based prioritization feature that allows a client to assign a priority for each stream through a PRIORITY frame. Stream priority determines the order at which the client wants its streams to be processed [5]. A client can also specify dependency between streams that will be expressed in a dependency tree at the server. It can assign weights to dependent streams to dictate to the server the relative proportion of available resources that it has to allocate them [5]. The dependency-based prioritization feature was introduced with the intention of improving user experience. However, since no limit was set in RFC 7540 [5] on the size of the dependency tree, a NFp which naively trusts a NFc may be deceived to build a dependency tree that will consume its memory and CPU, thus causing a DoS on the NFp [3], [13]. The exploitation of this feature can be partially limited in 5G SBA by configuring the size of dependency tree at NFp for each TCP connection.

        D. Header Compression

        HTTP/2 introduces header compression through the HPACK protocol to reduce the request size by eliminating redundant header fields across multiplexed streams, which leads to lower bandwidth utilization [5]. HTTP/2 request and response header metadata are compressed using HPACK through: (1) encoding the transmitted header fields to reduce their individual transfer size; (2) maintaining an HPACK static table that holds a predefined static list of headers; (3) updating and maintaining an HPACK dynamic table that holds a dynamic list of headers [5]. It is used as a cache for each connection direction separately. The sender can signal to the receiver what values to insert in the dynamic table, hence, it can refer to their locations in subsequent streams. The size of the dynamic table is restricted to limit the memory requirement on the decoder side, however, the size of the header value field inside this table is not constrained [5], [13]. The lack of restriction on the size of the header value creates a vulnerability that can be exploited to launch an HPACK Bomb attack [13]. An attacker can generate a first stream with a large header (i.e. , of size equal to the dynamic table of its peer), then open new streams over the same connection that reference the same header. Decompressing the large header for each subsequent stream causes memory exhaustion, and hence a Dos on the server [13]. Limiting the header value in the dynamic table can potentially prevent the HPACK Bomb attack.

        E. Server Push

        The server push uses the PUSH_PROMISE frame to enable the server to send inline resources to the client without an explicit request for each resource [5]. This feature improves the client's experience by reducing the load time and workload, however, it places the burden on the server. The server push feature, combined with the multiplexing feature can be misused to launch a Distributed Denial of Service (DDoS) attack against an HTTP/2 server. A malicious client can force a server to serve a high number of simultaneous requests, each of which
        """,

        enPaper8: """
        has multiple associated inline resources that the server needs to push [14]. This leads to a flooding attack which affects the server egress bandwidth and nearby routers, thus resulting in a DoS attack at the network layer as well [14]. The server push feature may not always be advantageous as it can use an excess of bandwidth to push unneeded assets. Mobile operators have to carefully assess the need for enabling this feature in their 5G networks as bandwidth and connection stability are crucial to meet the QoS requirements of their services.

        F. Discussion

        5G networks implement tighter security than the general web which reduces the likelihood of HTTP/2 attacks (Table I). Nonetheless, we believe that some of these HTTP/2 attacks are likely to apply to SG networks as they can be exploited by attackers through vulnerabilities related to virtualization technologies [7]. In fact, the move of mobile network operators to the public cloud increases the attack surface through virtualization vulnerabilities (e.g. , CVE-2016-5195, CVE-2019-5736). Similarly, virtualization vulnerabilities and misconfiguration can be exploited by attackers to breach the isolation between 5G network slices through for example a shared NF [15]. In such a scenario, HTTP/2 attacks on the shared NF from one slice can impact the functionality of the other slice. Further, HTTP/2 attacks can be initiated from malicious roaming partner and remain undetected by the filtering techniques at the SEPP [10]. Although they take a new form in HTTP/2, HTTP/2 multiplexing and slow-read attacks common in the Internet, may occur now in 5G networks. In contrast, we envision that stream dependency and prioritization based attacks along with server push and HPACK bomb attacks are less likely to happen in 5G networks as they are highly related to the mobile operators implementation and configuration. For instance, an operator may choose to disable server push functionality, thus preventing its related attack. To the best of our knowledge, the usage of server push has been left by 3GPP to the mobile operator choice. Finally, with the risk of misconfiguration of HTTP/2 settings and its related attacks, intelligent anomaly detection solutions that can detect HTTP/2 attacks to enable automated mitigation measures are needed.

        IV. IMPLICATIONS OF HTTP/2 STANDARD AND CUSTOM HEADERS ON 5G SBA

        HTTP/2 message header is composed of multiple standard and custom header fields that we elucidate and discuss their role in 5G SBA security.

        A. Standard HTTP/2 Headers

        The standard HTTP/2 header fields are used in both requests and responses. The request sent to the HTTP/2 server includes a list of header fields that identify the client. Figure 2 includes some of these standard headers: accept-encoding specifies the used data encoding; accept determines the content type the client is able to handle; authority defines the Fully Qualified Domain Name (FQDN) or IP address of the target Uniform
        """,

        enPaper9: """
        Resource Identifier (URI) (i.e. , target NF service); path includes the path and query parts of the target URI (i.e. , API URI); scheme declares the version of HTTP used (e.g. , http or https) [5], [6]. User-agent header key defines the HTTP/2 client. An HTTP/2 response carries HTTP header response fields (Figure 2) such as: status which carries the HTTP status code, content-type specifies the type of the content returned by the server, content-length determines the length of the content in bytes, and the originating date of the response presented in the date header (5], 16].

        #HTTP Request Header
        accept-encoding: gzip
        accept: application/ json
        : authority: amf.5g.org: 8000
        : method: POST
        : path:

        /namf-comm/v1/ue-contexts/ {ueId) /n1-n2-messages version: HTTP /2.0
        : scheme: https
        user-agent: SME

        #HTTP Response Header
        : status: 200 OK
        content-type: application/ json
        content-length: 5613
        date: Mon, 14 March 2022 09: 44: 16 GMT

        Fig. 2: HTTP/2 request and response headers.

        Furthermore, other HTTP standard header fields such as Authorization in the request and WWW-Authenticate in the response are used to mitigate multiple attacks on 5G NFs that could originate from a third party connection (e.g. , roaming partner). For example, the Authorization header holds the OAuth 2.0 access token (Section II-D) that the NFp should validate (i.e. , validate the token, its expiry date and access scope) before granting access to the requested resource |6]. In case the OAuth 2.0 access token was deemed invalid by the NFp (i.e. , expired token, or the required scopes to invoke the requested service operation is not covered by the token); the NFp rejects the API request. The NFp will use the WWW-Authenticate header to determine the reason behind the rejection (i.e. , invalid token, insufficient scope) in its error attribute [6], [12].

        B. Custom HTTP/2 Headers

        3GPP introduced HTTP/2 custom headers dedicated for 5G SBA. Some of these custom headers are defined to enable load and overload control as they allow sharing of NFs load information [6]. Hereafter, we discuss the importance of these custom headers on 5G SBA security.

        1) 3gpp-Sbi-Lci: 3gpp-Sbi-Lci enables a NFp to signal its Load Control Information (LCI) to a NFc either directly or through the NRF during service discovery. This enables the NFc to decide whether or not to select a different NFp, hence, enabling a better load balancing in the network. Figure 3 represents a 3gpp-Sbi-Lci custom header, generated on specific date/time defined in Timestamp, by a NFp, to signal its load level through the Load-Metric to a SCP instance (i.e. , SCP1 specified in SCP-FQDN) [6].
        """,

        enPaper10: """
        3gpp-Sbi-Lci: Timestamp: "Tue, 04 Feb 2020 08: 49: 37

        GMT"; Load-Metric: 25%; SCP-FQDN: scpl.example.com

        Fig. 3: LCI for SCP [6].

        2) 3gpp-Sbi-Oci: A NFp/NFc uses the 3gpp-Sbi-Oci custom header to signal its Overload Control Information (OCI) to its peer. Through this header, the overloaded NF instructs its peer to throttle the service/notification requests, in an attempt to reduce its signalling load [6]. Figure 4 depicts a 3gpp-SbiOci header sent by a NFp, identified by its instance ID (1. e. , NF-Instance), asking a NFc to throttle 50% of its requests as determined in Overload-Reduction-Metric. Note that an Overload-Reduction-Metric of "0" indicates that the sender is not overloaded. The 3gpp-Sbi-Oci also includes the Timestamp indicating the time at which it was generated and its validity period identified by Period-of-Validity [6].

        3gpp-Sbi-Oci: Timestamp: "Tue, 29 Mar 2021 08: 49: 37

        GMT"; Period-of-Validity: 75s; Overload-Reduction-Metric: 50%; NE-Instance: 54804518-4191-46b3-955c-ac631f953ed8

        Fig. 4: OCI for a NF Instance [6].

        3) 3gpp-Sbi-Message-Priority: In contrast to the PRIORITY frame used to determine stream (i.e. , request and response) priority at the connection level, 3GPP introduced the 3gpp-Sbi-Message-Priority to provide the flexibility of assigning a priority for the response that differs of the one assigned to its corresponding request (5], l6]. The primary usage of SBl Message Priority (SMP) is to assist NFp/NFc/proxies when making throttling decision related to an overload control or when routing messages through proxies [6]. For instance, a server may process higher-priority messages first, however, this may block lower-priority messages from ever being handled. In SG SBA, this will result in the messages being retried, and in more traffic than the network usually handles without the use of the SMP mechanism.

        C. Security Implications

        HTTP/2 standard and custom headers play a critical role in security enforcement. HTTP/2 standard headers include APIs information and handle authentication and service authorization in 5G, thus, preventing illegal service access. In contrast, 3GPP custom headers prevent DoS and DDoS attacks by enabling load balancing on NFs through 3 gpp-SbiLci, and overload handling using 3gpp-Sbi-Oci while staying compliant with the message priority defined in 3gpp-SbiMessage-Priority. However, 3gpp-Sbi-Message-Priority can be abused and result in starving of low-priority messages. This unwanted starving needs to be correctly handled by following 3GPP recommendations on the usage of this header and by limiting the number of higher-priority messages in comparison to lower-priority ones [6]. Similarly, 3gpp-Sbi-Lci and 3gppSbi-Oci can be abused by attackers to trick the network into assuming that a certain NF is (over)loaded by forging the Overload-Reduction-Metric in OCI and Load-Metric in LCI. This may trigger unneeded scaling of the victim NF which
        """,

        enPaper11: """
        may lead to over-provisioning and hence, incur revenue losses for the operator.

        V. SECURITY CHALLENGES AND OPPORTUNITIES

        In the following, we discuss existing security challenges and shed light on possible security opportunities and research directions that can play a critical role to address them Figure 5.

        A. Broken Service Access Control

        The use of token-based authorization through OAuth 2.0 exposes the 5G network to token tampering attack, allowing attackers to access the services of another NF within the same or different Public Land Mobile Network (PLMN). It also enables them to launch a Dos attack on the NFc by replacing the granted service (i.e. , API) of the NFp in the request with an unavailable one [7]. The risk of gaining unauthorized service access through NF-NRF interface is also possible and can result in the disclosure of sensitive information of a PLMN [10]. A holistic distributed attack detection and network monitoring framework is intrinsic to reveal unauthorized access and alert NFs of tampered tokens that need to be revoked and malicious requests that should be rejected. Further, with the large number of roaming partners that an operator can have, misconfiguration of authorization rules is possible [10). This requires standard contracts and authorization templates to lighten the configuration burden.

        B. Broken Authentication

        The usage of TLS for SBA protection at the network and transport layer, and for service authorization respectively, relies on Public-Key Infrastructure (PKI) (i.e. , X. 509 certificate, public/private keys) [4], [8]. In a non-roaming scenario, there
        """,

        enPaper12: """
        is a risk of fraudulent certificates and compromise of private keys, whereas in a roaming scenario, the roaming database (IR. 21) may contain outdated information and revoked certificates. This can result in broken authentication which can lead to compromising JSON web token (i.e. , used between SEPPs of roaming partners) and hence, grant illegal network access [10]. Thus, automated certificate management and storage of related keys to cope with the dynamism of 5G cloud-native environment are research questions that are yet to be explored [8].

        C. API Exploitation

        The reliance of 5G SBA on APIs extends the 5G attack surface to vulnerabilities associated with their exploitation. APIs are exposed to all endpoints within the same PLMN or with roaming partners through the SEPP.

        DoS attacks can be launched by exploiting the resources an API can consume in case no limits are imposed on the size or the number of those resources [10]. Attackers can exploit HTTP/2 multiplexing feature to overload the NFp with requests exploiting APIs that require heavy resource consumption from the server. The attack can be further exacerbated by a slow-read attack during which the attacker manipulates the flow-control information to keep the NFp resources allocated for those requests for a longer period of time, hence facilitating the DoS. Therefore, proper configuration of HTTP/2 settings such as SETTINGS_MAX_CONCURRENT_STREAMS to limit DoS attacks is also needed. For instance, a network operator can limit the number of maximum concurrent streams that a server allows per connection. This will make a DoS attack costly to the attacker who will need to allocate more resources to establish multiple TCP connections with the server to exhaust it. Further, HTTP/2 with usage of SCP in
        """,

        enPaper13: """
        a 5G network offers many opportunities for early detection and mitigation of a server overload and DoS attacks through the use of HTTP/2 custom headers standardized by 3GPP for 5G SBA (Section IV-B).

        D. HTTP/2 Attacks and Interconnect Security

        HTTP/2 attacks can be left unnoticed by the SEPP at the interconnect network on the N32 interface (Figure 1), if they originated from malicious roaming partners [4], [10]. HTTP/2 filtering at the SEPP aims at blocking 5G interconnect messages based on certain criteria (i.e. , URI, specific IEs, etc. ) to prevent malicious roaming partners from extending their services beyond the roaming agreement. Nonetheless, filtering techniques do not prevent attacks such as HTTP/2 multiplexing attacks in which malicious roaming partners can request legitimate services from a specific NF

        To counter the above threats, intelligent threat analysis and detection solutions that overcome the limitations of filtering mechanisms and which leverage Machine Learning (ML) and Artificial Intelligence (AI) techniques are needed. They can learn traffic pattern from data collected at filtering nodes such as the SEPP, 5G NFs and other monitoring logs collected from the 5G SBA. Real time or near real time traffic analysis and features extraction at network and application layers while accounting for API calls, IEs, HTTP/2 standards and custom headers are yet to be explored as indicators of compromise that may enhance the detection accuracy of these ML/AI models that yet to be developed. Further, ML/AI solutions need to be complemented with effective incident analysis and response and used to automatically update filtering rules at the SEPP and the 5G SBA firewalls. The proposed security controls should be designed to complement each other in an automated holistic security orchestration and management framework designed and adapted for 5G networks.

        VI. CONCLUSION

        This article explored the main security features introduced in 5G SBA with a focus on the security implications of using HTTP/2 as the signalling protocol in conjunction with other web-based technologies (i.e. , JSON, RESTful API), and security protocols (i.e. , OAuth 2.0, TLS). We argued that HTTP/2 serves 5G through the freedom it offers to HTTP/2 clients to instruct an HTTP/ server on the processing of their requests. It also adds a new layer of security to 5G signalling through its 3GPP standards and custom headers. Nonetheless, some security challenges are brought by HTTP/2 and the web-based protocol suite. We show in this paper that these challenges can be addressed by intelligent application layer security, monitoring systems, and intelligent anomaly detection solutions to enable automated mitigation measures as building blocks for anticipated security guarantees in the face of the evolving 5G threat landscape.

        REFERENCES

        [1] I. Ahmad, S. Shahabuddin, T. Kumar, J. Okwuibe, A. Gurtov, and M. Ylianttila, "Security for 5g and beyond, " IEEE Communications Surveys & Tutorials, vol. 21, no. 4, pp. 3682-3722, 2019.
        """,

        .enPoetry8: """
        I Pass by in Silence

        I talk to the birds as they sing for tomorrow,
        the larks and the sparrows that spring from the corn,
        the chaffinch and linnet that sing in the bush,
        till the zephyr-like breezes all bid me to hush;
        then silent I go and in fancy I steal,
        a kiss from the lips of a name I conceal;
        but should Imeet her I've cherished for years,
        I pass by in silence, in fondness and tears.

        yes, I pass her in silence and say not a word,
        and the noise of my footsteps may scarcely be heard;
        I scarcely presume to cast on her my eye,
        and then for a week I do nothing but sigh.
        if Ilook on a wild flower i see her face there,
        there it is in its beauty, all radiant and fair;
        and should she pass by, I've nothing to say,
        we are both of silent and have our own way.

        I talk to the birds, the wind and the rain,
        my love to my dear one i never explain;
        I talk to the flowers which are growing all wild,
        as if one was herself and the other her child;
        I utter sweet words in my fanciful way,
        but if she comes by I've nothing to say;
        to look for a kiss I would if I dare,
        but I feel myself lost when near to my fair.

        -- John Clare
        """,
    ]
}

// swiftlint:enable line_length
