{
    "@id": $name,
    "listen": [
      $from
    ],
    "logs": {
      "logger_names": {
        ($hostport): $name
      }
    },
    "routes": [
      {
        "handle": [
          {
            "handler": "subroute",
            "routes": [
              {
                "handle": [
                  {
                    "handler": "reverse_proxy",
                    "upstreams": [
                      {
                        "dial": $to
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ],
        "match": [
          {
            "host": [
              $host
            ]
          }
        ],
        "terminal": true
      }
    ]
}
