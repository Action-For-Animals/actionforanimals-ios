//
//  PreviewIssues.swift
//  ActionForAnimals
//
//  Created by Nick O'Neill on 6/28/23.
//  Copyright © 2023 5calls. All rights reserved.
//

import Foundation

extension AnimalPolicy {
    static let issueReason = """
    Congress is currently considering [the RESTRICT Act](https://www.warner.senate.gov/public/index.cfm/2023/3/senators-introduce-bipartisan-bill-to-tackle-national-security-threats-from-foreign-tech), [(S.686)](https://www.congress.gov/bill/118th-congress/senate-bill/686) a bill that purports to protect Americans by restricting access to apps and websites that could pose a threat to national security.
    
    ~this is very important.~
    
    ~~this is also very important.~~

    Demand your Senators oppose the RESTRICT Act to ensure a free and fair internet.
    """
    
    static let issueScript = """
    Hi, my name is **[NAME]** and I'm a constituent from [CITY, ZIP].

    I'm calling to demand [REP/SEN NAME] oppose S. 686, the RESTRICT Act. The legislation would do nothing to protect Americans and would give potential future Presidents more tools to abuse their power.

    Thank you for your time and consideration.

    **IF LEAVING VOICEMAIL:** Please leave your full street address to ensure your call is tallied.
    """
    
    // Corporate campaign script example
    static let corporateScript = """
    Hi, my name is **[NAME]** and I'm a customer of **[TARGET_COMPANY]**.

    I'm calling to ask **[TARGET_COMPANY]** to commit to ending the sale of live animals in your stores and instead partner exclusively with local shelters and rescues for pet adoptions.

    The retail sale of animals contributes to puppy mills and takes homes away from shelter animals who need them. Will **[TARGET_COMPANY]** commit to this change?

    Thank you for your time.
    """
    
    static let basicPreviewIssue = AnimalPolicy(
        id: 813,
        meta: "",
        name: "Support the Act",
        slug: "support-act-slug",
        reason: AnimalPolicy.issueReason,
        script: AnimalPolicy.issueScript,
        categories: [Category(name: "Budget")],
        active: true,
        outcomeModels: [Outcome(label: "Contacted", status: "contact"), Outcome(label: "Voicemail", status: "voicemail")],
        contactType: .representatives,
        contactAreas: ["US House", "US Senate"],
        createdAt: Date(timeIntervalSince1970: 1688015904),
        status: "active",
        stats: Stats(calls: 0, emails: nil, totalActions: 0),
        animalsHelped: 3,
        targets: nil,
        actions: nil,
        corporateInfo: nil
    )
    
    static let multilinePreviewIssue = AnimalPolicy(
        id: 812,
        meta: "",
        name: "Support the Act whose name is quite long",
        slug: "support-act-slug2",
        reason: AnimalPolicy.issueReason,
        script: AnimalPolicy.issueScript,
        categories: [Category(name: "Environment")],
        active: true,
        outcomeModels: [Outcome(label: "Contacted", status: "contact"), Outcome(label: "Voicemail", status: "voicemail")],
        contactType: .representatives,
        contactAreas: ["US House", "US Senate"],
        createdAt: Date(timeIntervalSince1970: 1688015904),
        status: "active",
        stats: Stats(calls: 0, emails: nil, totalActions: 0),
        animalsHelped: 3,
        targets: nil,
        actions: nil,
        corporateInfo: nil
    )
    
    static let extraLongPreviewIssue = AnimalPolicy(
        id: 811,
        meta: "",
        name: "Call for supportive action in a made up region with extra long details",
        slug: "support-act-slug2",
        reason: AnimalPolicy.issueReason,
        script: AnimalPolicy.issueScript,
        categories: [Category(name: "Environment")],
        active: true,
        outcomeModels: [Outcome(label: "Contacted", status: "contact"), Outcome(label: "Voicemail", status: "voicemail")],
        contactType: .representatives,
        contactAreas: ["US House", "US Senate"],
        createdAt: Date(timeIntervalSince1970: 1688015904),
        status: "active",
        stats: Stats(calls: 0, emails: nil, totalActions: 0),
        animalsHelped: 3,
        targets: nil,
        actions: nil,
        corporateInfo: nil
    )
    
    static let houseOnlyPreviewIssue = AnimalPolicy(
        id: 813,
        meta: "",
        name: "Support the Act",
        slug: "support-act-slug",
        reason: AnimalPolicy.issueReason,
        script: AnimalPolicy.issueScript,
        categories: [Category(name: "Budget")],
        active: true,
        outcomeModels: [Outcome(label: "Contacted", status: "contact"), Outcome(label: "Voicemail", status: "voicemail")],
        contactType: .representatives,
        contactAreas: ["US House"],
        createdAt: Date(timeIntervalSince1970: 1688015904),
        status: "active",
        stats: Stats(calls: 0, emails: nil, totalActions: 0),
        animalsHelped: 3,
        targets: nil,
        actions: nil,
        corporateInfo: nil
    )
    
    static let senateOnlyPreviewIssue = AnimalPolicy(
        id: 813,
        meta: "",
        name: "Support the Act",
        slug: "support-act-slug",
        reason: AnimalPolicy.issueReason,
        script: AnimalPolicy.issueScript,
        categories: [Category(name: "Budget")],
        active: true,
        outcomeModels: [Outcome(label: "Contacted", status: "contact"), Outcome(label: "Voicemail", status: "voicemail")],
        contactType: .representatives,
        contactAreas: ["US Senate"],
        createdAt: Date(timeIntervalSince1970: 1688015904),
        status: "active",
        stats: Stats(calls: 0, emails: nil, totalActions: 0),
        animalsHelped: 3,
        targets: nil,
        actions: nil,
        corporateInfo: nil
    )
    
    // NEW: Corporate campaign preview issue
    static let corporatePreviewIssue = AnimalPolicy(
        id: 2001,
        meta: "end-animal-sales",
        name: "End Retail Sales of Animals at Petco",
        slug: "petco-end-animal-sales",
        reason: "Petco continues to sell live animals in their stores, contributing to the puppy mill industry and pet overpopulation crisis. Many animals in pet stores come from commercial breeding facilities with poor conditions, and retail sales compete with shelter adoptions.",
        script: AnimalPolicy.corporateScript,
        categories: [Category(name: "Companion Animals")],
        active: true,
        outcomeModels: [
            Outcome(label: "Contacted", status: "contact"),
            Outcome(label: "Voicemail", status: "voicemail"),
            Outcome(label: "Commitment Received", status: "success")
        ],
        contactType: .corporate,
        contactAreas: ["Pet Retail", "Corporate"],
        createdAt: Date(timeIntervalSince1970: 1725811200),
        status: "active",
        stats: Stats(calls: 0, emails: 0, totalActions: 0),
        animalsHelped: 5,
        targets: [
            Target(
                id: "petco-customer-service",
                name: "Petco Animal Supplies - Customer Service",
                email: "customerrelations@petco.com",
                phone: "1-888-824-7257",
                department: "Customer Relations",
                jobTitle: "Customer Service Representative"
            )
        ],
        actions: Actions(
            call: CallAction(
                enabled: true,
                script: AnimalPolicy.corporateScript
            ),
            email: EmailAction(
                enabled: true,
                distributionMethod: "individual",
                subject: "Customer Request: End Live Animal Sales",
                template: """
                Dear **[TARGET_COMPANY]** Leadership,

                As a loyal customer, I'm writing to ask **[TARGET_COMPANY]** to stop selling live animals in your retail locations.

                The retail pet industry contributes to:
                • Puppy mill operations with poor breeding conditions
                • Pet overpopulation while shelter animals need homes
                • Impulse purchases leading to abandoned pets

                Many progressive retailers have already transitioned to adoption-only models, partnering with local shelters and rescues. This approach saves lives while still helping customers find their perfect companion.

                Please commit to ending live animal sales and focusing exclusively on adoption partnerships.

                Sincerely,
                **[NAME]**
                Customer since **[CUSTOMER_SINCE]**
                Location: **[CITY, ZIP]**
                """
            )
        ),
        corporateInfo: CorporateInfo(
            company: "Petco Animal Supplies",
            industry: "Pet Retail",
            ticker: "WOOF",
            headquarters: "San Diego, CA"
        )
    )
}
