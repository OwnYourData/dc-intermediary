{
    "@context": {
        "@version": 1.1,
        "@vocab": "https://soya.ownyourdata.eu/SCM_UsagePolicy/",
        "dpvo": "https://w3id.org/dpv/dpv-owl#",
        "scdv": "https://w3id.org/scdv/v1#",
        "dpvo:hasPurpose": {
            "@type": "@id"
        },
        "dpvo:hasProcessing": {
            "@type": "@id"
        },
        "dpvo:hasRecipient": {
            "@type": "@id"
        },
        "dpvo:hasLocation": {
            "@type": "@id"
        },
        "dpvo:hasExpiryTime": {
            "@type": "http://www.w3.org/2001/XMLSchema#dateTime"
        }
    },
    "@graph": [
        {
            "@type": "SCM_UsagePolicy",
            "dpvo:hasPurpose": [],
            "dpvo:hasProcessing": (.verifiableCredential[0].credentialSubject.purposes[0].processing_method | split(", ") | map("scdv:\( .[:1] | ascii_upcase)\(.[1:] )")),
            "dpvo:hasRecipient": [],
            "dpvo:hasLocation": [(if .verifiableCredential[0].credentialSubject.purposes[0].storage_location == "EEC" then "scdv:EU" else empty end)],
            "dpvo:hasExpiryTime": "1970-01-01T00:00:00"
        }
    ]
}