(() => {
    const collectionName = "scan_sessions";
    const database = db.getSiblingDB(nomeDB);

    const validator = {
      $and: [
        {
          $jsonSchema: {
            bsonType: "object",
            title: "venus_scan validator",

            required: [
              "scan_id",
              "status",
              "source",
              "device",
              "workflow",
              "quality_check",
              "images",
              "ocr",
              "interpretation",
              "admin_review",
              "postgres_projection",
              "postgres_sync",
              "created_at",
              "updated_at"
            ],

            properties: {
              scan_id: {
                bsonType: "string",
                pattern: "^VS-",
                description: "obrigatório, identificador público do scan"
              },

              status: {
                enum: [
                  "pending_review",
                  "in_review",
                  "approved",
                  "rejected",
                  "sync_failed",
                  "synced"
                ]
              },

              source: {
                bsonType: "object",
                required: ["type", "channel", "submitted_at"],
                properties: {
                  type: {
                    enum: ["ocr", "manual", "import"]
                  },
                  channel: {
                    bsonType: "string"
                  },
                  submitted_at: {
                    bsonType: "date"
                  },
                  user: {
                    bsonType: "object",
                    properties: {
                      user_id: {
                        bsonType: ["string", "null"]
                      },
                      firebase_uid: {
                        bsonType: ["string", "null"]
                      },
                      name_snapshot: {
                        bsonType: ["string", "null"]
                      }
                    }
                  }
                }
              },

              device: {
                bsonType: "object",
                required: ["platform"],
                properties: {
                  device_id: {
                    bsonType: "string"
                  },
                  platform: {
                    enum: ["android", "ios", "web", "server"]
                  },
                  app_version: {
                    bsonType: "string"
                  },
                  model: {
                    bsonType: "string"
                  }
                }
              },

              workflow: {
                bsonType: "object",
                required: ["scan_type", "current_step"],
                properties: {
                  scan_type: {
                    enum: ["front", "back", "combined"]
                  },
                  current_step: {
                    bsonType: "string"
                  },
                  started_at: {
                    bsonType: ["date", "null"]
                  },
                  finished_at: {
                    bsonType: ["date", "null"]
                  }
                }
              },

              quality_check: {
                bsonType: "object",
                properties: {
                  blur_score: {
                    bsonType: ["double", "int"],
                    minimum: 0,
                    maximum: 1
                  },
                  brightness: {
                    bsonType: ["double", "int"],
                    minimum: 0,
                    maximum: 1
                  },
                  background_ok: {
                    bsonType: "bool"
                  },
                  status: {
                    enum: ["accepted", "rejected", "pending"]
                  },
                  checked_at: {
                    bsonType: ["date", "null"]
                  }
                }
              },

              images: {
                bsonType: "object",
                minProperties: 1,
                additionalProperties: false,
                properties: {
                  front: {
                    bsonType: "object",
                    required: [
                      "storage_provider",
                      "public_id",
                      "secure_url"
                    ],
                    properties: {
                      storage_provider: {
                        bsonType: "string"
                      },
                      public_id: {
                        bsonType: "string"
                      },
                      secure_url: {
                        bsonType: "string"
                      },
                      source_type: {
                        enum: [
                          "user_submission",
                          "admin_upload",
                          "import"
                        ]
                      },
                      captured_at: {
                        bsonType: ["date", "null"]
                      }
                    }
                  },

                  back: {
                    bsonType: "object",
                    required: [
                      "storage_provider",
                      "public_id",
                      "secure_url"
                    ],
                    properties: {
                      storage_provider: {
                        bsonType: "string"
                      },
                      public_id: {
                        bsonType: "string"
                      },
                      secure_url: {
                        bsonType: "string"
                      },
                      source_type: {
                        enum: [
                          "user_submission",
                          "admin_upload",
                          "import"
                        ]
                      },
                      captured_at: {
                        bsonType: ["date", "null"]
                      }
                    }
                  }
                }
              },

              ocr: {
                bsonType: "object",
                minProperties: 1,
                additionalProperties: false,
                properties: {
                  front: {
                    bsonType: "object",
                    required: ["full_text", "extracted"],
                    properties: {
                      full_text: {
                        bsonType: "string"
                      },
                      extracted: {
                        bsonType: "object"
                      }
                    }
                  },

                  back: {
                    bsonType: "object",
                    required: ["full_text", "extracted"],
                    properties: {
                      full_text: {
                        bsonType: "string"
                      },
                      extracted: {
                        bsonType: "object",
                        properties: {
                          ingredient_section_found: {
                            bsonType: "bool"
                          },

                          ingredients: {
                            bsonType: "array",
                            items: {
                              bsonType: "object",
                              required: [
                                "raw_name",
                                "normalized_name",
                                "status",
                                "match",
                                "admin_decision"
                              ],
                              properties: {
                                position: {
                                  bsonType: "int"
                                },
                                raw_name: {
                                  bsonType: "string"
                                },
                                normalized_name: {
                                  bsonType: "string"
                                },
                                status: {
                                  enum: ["RESOLVED", "UNRESOLVED"]
                                },

                                match: {
                                  bsonType: "object",
                                  required: ["status"],
                                  properties: {
                                    status: {
                                      enum: [
                                        "known",
                                        "alias",
                                        "ambiguous",
                                        "new",
                                        "unresolved"
                                      ]
                                    },
                                    confidence: {
                                      bsonType: ["double", "int"],
                                      minimum: 0,
                                      maximum: 1
                                    },
                                    postgres_ingredient_id: {
                                      bsonType: ["int", "null"]
                                    },
                                    candidates: {
                                      bsonType: "array",
                                      items: {
                                        bsonType: "string"
                                      }
                                    }
                                  }
                                },

                                admin_decision: {
                                  bsonType: "object",
                                  required: ["action"],
                                  properties: {
                                    action: {
                                      enum: [
                                        "pending",
                                        "keep",
                                        "link",
                                        "create",
                                        "reject"
                                      ]
                                    },
                                    final_ingredient_id: {
                                      bsonType: ["int", "null"]
                                    },
                                    create_unverified: {
                                      bsonType: "bool"
                                    },
                                    decided_by: {
                                      bsonType: ["string", "null"]
                                    },
                                    decided_at: {
                                      bsonType: ["date", "null"]
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              },

              interpretation: {
                bsonType: "object",
                properties: {
                  product_match: {
                    bsonType: "object",
                    properties: {
                      status: {
                        enum: [
                          "found",
                          "not_found",
                          "ambiguous",
                          "error"
                        ]
                      },
                      score: {
                        bsonType: ["double", "int"],
                        minimum: 0,
                        maximum: 1
                      }
                    }
                  },

                  brand_resolution: {
                    bsonType: "object",
                    properties: {
                      status: {
                        enum: [
                          "matched",
                          "new",
                          "ambiguous",
                          "unresolved"
                        ]
                      },
                      confidence: {
                        bsonType: ["double", "int"],
                        minimum: 0,
                        maximum: 1
                      },
                      admin_required: {
                        bsonType: "bool"
                      }
                    }
                  },

                  category_resolution: {
                    bsonType: "object",
                    properties: {
                      status: {
                        enum: [
                          "matched",
                          "new",
                          "ambiguous",
                          "unresolved"
                        ]
                      },
                      confidence: {
                        bsonType: ["double", "int"],
                        minimum: 0,
                        maximum: 1
                      },
                      admin_required: {
                        bsonType: "bool"
                      }
                    }
                  },

                  claims: {
                    bsonType: "array",
                    items: {
                      bsonType: "object",
                      properties: {
                        match_status: {
                          enum: [
                            "known",
                            "new",
                            "ambiguous",
                            "unresolved"
                          ]
                        },
                        admin_action: {
                          enum: [
                            "pending",
                            "keep",
                            "link",
                            "create",
                            "reject"
                          ]
                        },
                        was_verified: {
                          bsonType: "bool"
                        }
                      }
                    }
                  }
                }
              },

              admin_review: {
                bsonType: "object",
                required: ["decision"],
                properties: {
                  queue: {
                    bsonType: "object",
                    properties: {
                      status: {
                        bsonType: "string"
                      },
                      priority: {
                        enum: ["low", "normal", "high"]
                      },
                      tags: {
                        bsonType: "array",
                        items: {
                          bsonType: "string"
                        }
                      }
                    }
                  },

                  assigned_admin_id: {
                    bsonType: ["string", "null"]
                  },
                  decision: {
                    enum: ["pending", "approved", "rejected"]
                  },
                  decided_at: {
                    bsonType: ["date", "null"]
                  },
                  rejection_reason: {
                    bsonType: ["string", "null"]
                  },

                  history: {
                    bsonType: "array",
                    items: {
                      bsonType: "object",
                      required: ["action", "at"],
                      properties: {
                        action: {
                          bsonType: "string"
                        },
                        admin_id: {
                          bsonType: ["string", "null"]
                        },
                        at: {
                          bsonType: "date"
                        },
                        reason: {
                          bsonType: ["string", "null"]
                        }
                      }
                    }
                  }
                }
              },

              postgres_projection: {
                bsonType: "object",
                properties: {
                  ready_to_sync: {
                    bsonType: "bool"
                  },
                  validation_errors: {
                    bsonType: "array",
                    items: {
                      bsonType: "string"
                    }
                  },

                  brand: {
                    bsonType: "object",
                    properties: {
                      action: {
                        enum: ["link", "create"]
                      }
                    }
                  },

                  product: {
                    bsonType: "object",
                    properties: {
                      action: {
                        enum: ["create", "reuse"]
                      }
                    }
                  },

                  product_version: {
                    bsonType: "object",
                    properties: {
                      action: {
                        enum: ["create"]
                      },
                      payload: {
                        bsonType: ["object", "null"],
                        properties: {
                          status: {
                            enum: ["pending", "approved", "rejected"]
                          }
                        }
                      }
                    }
                  }
                }
              },

              postgres_sync: {
                bsonType: "object",
                required: ["status", "idempotency_key", "attempt"],
                properties: {
                  status: {
                    enum: [
                      "not_started",
                      "pending",
                      "processing",
                      "succeeded",
                      "failed"
                    ]
                  },
                  idempotency_key: {
                    bsonType: "string"
                  },
                  started_at: {
                    bsonType: ["date", "null"]
                  },
                  completed_at: {
                    bsonType: ["date", "null"]
                  },
                  attempt: {
                    bsonType: "int",
                    minimum: 0
                  },
                  error_code: {
                    bsonType: ["string", "null"]
                  },
                  error_message: {
                    bsonType: ["string", "null"]
                  }
                }
              },

              created_at: {
                bsonType: "date"
              },
              updated_at: {
                bsonType: "date"
              }
            }
          }
        },

        {
          $expr: {
            $switch: {
              branches: [
                {
                  case: {
                    $eq: ["$workflow.scan_type", "front"]
                  },
                  then: {
                    $and: [
                      {
                        $ne: ["$images.front", null]
                      },
                      {
                        $eq: [
                          { $ifNull: ["$images.back", null] },
                          null
                        ]
                      },
                      {
                        $ne: ["$ocr.front", null]
                      },
                      {
                        $eq: [
                          { $ifNull: ["$ocr.back", null] },
                          null
                        ]
                      }
                    ]
                  }
                },

                {
                  case: {
                    $eq: ["$workflow.scan_type", "back"]
                  },
                  then: {
                    $and: [
                      {
                        $ne: ["$images.back", null]
                      },
                      {
                        $eq: [
                          { $ifNull: ["$images.front", null] },
                          null
                        ]
                      },
                      {
                        $ne: ["$ocr.back", null]
                      },
                      {
                        $eq: [
                          { $ifNull: ["$ocr.front", null] },
                          null
                        ]
                      }
                    ]
                  }
                },

                {
                  case: {
                    $eq: ["$workflow.scan_type", "combined"]
                  },
                  then: {
                    $and: [
                      {
                        $ne: ["$images.front", null]
                      },
                      {
                        $ne: ["$images.back", null]
                      },
                      {
                        $ne: ["$ocr.front", null]
                      },
                      {
                        $ne: ["$ocr.back", null]
                      }
                    ]
                  }
                }
              ],
              default: false
            }
          }
        }
      ]
    };

    const validationOptions = {
      validator,
      validationLevel: "strict",
      validationAction: "error"
    };

    const exists =
      database.getCollectionInfos({ name: collectionName }).length > 0;

    const command = exists
      ? {
          collMod: collectionName,
          ...validationOptions
        }
      : {
          create: collectionName,
          ...validationOptions
        };

    const result = database.runCommand(command);

    if (result.ok !== 1) {
      printjson(result);
      throw new Error("Falha ao aplicar o validador.");
    }

    print("Validador aplicado");

    printjson(
      database.getCollectionInfos({ name: collectionName })[0].options
    );
  })();
