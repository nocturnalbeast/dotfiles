#![enable(implicit_some, unwrap_newtypes, unwrap_variant_newtypes)]
(
    default_album_art_path: None,
    show_song_table_header: true,
    draw_borders: false,
    browser_column_widths: [
        20,
        38,
        42,
    ],
    background_color: "black",
    text_color: "{base06}",
    header_background_color: "black",
    modal_background_color: "black",
    tab_bar: (
        enabled: true,
        active_style: (
            fg: "{base00}",
            bg: "{base06}",
            modifiers: "Bold",
        ),
        inactive_style: (
            fg: "{base06}",
            bg: "black",
        ),
    ),
    highlighted_item_style: (
        fg: "{base07}",
        modifiers: "Bold",
    ),
    current_item_style: (
        fg: "{base00}",
        bg: "{accent}",
        modifiers: "Bold",
    ),
    borders_style: (
        fg: "{base03}",
    ),
    highlight_border_style: (
        fg: "{accent}",
    ),
    symbols: (
        song: "S",
        dir: "D",
        marker: "M",
        ellipsis: "...",
    ),
    progress_bar: (
        symbols: [
            "█",
            "▌",
            " ",
        ],
        track_style: (
            fg: "{base03}",
        ),
        elapsed_style: (
            fg: "{accent}",
        ),
        thumb_style: (
            fg: "{accent}",
        ),
    ),
    scrollbar: (
        symbols: [
            " ",
            "█",
            "▲",
            "▼",
        ],
        track_style: (
            fg: "{base03}",
        ),
        ends_style: (
            fg: "{base04}",
        ),
        thumb_style: (
            fg: "{accent}",
        ),
    ),
    song_table_format: [
        (
            prop: (
                kind: Property(Artist),
                default: (
                    kind: Text("Unknown"),
                ),
            ),
            width: "20%",
        ),
        (
            prop: (
                kind: Property(Title),
                default: (
                    kind: Text("Unknown"),
                ),
            ),
            width: "35%",
        ),
        (
            prop: (
                kind: Property(Album),
                style: (
                    fg: "{base05}",
                ),
                default: (
                    kind: Text("Unknown Album"),
                    style: (
                        fg: "{base03}",
                    ),
                ),
            ),
            width: "30%",
        ),
        (
            prop: (
                kind: Property(Duration),
                default: (
                    kind: Text("-"),
                ),
            ),
            width: "15%",
            alignment: Right,
        ),
    ],
    layout: Split(
        direction: Vertical,
        panes: [
            (
                size: "100%",
                pane: Split(
                    direction: Horizontal,
                    panes: [
                        (
                            size: "30%",
                            borders: "ALL",
                            pane: Split(
                                direction: Vertical,
                                panes: [
                                    (
                                        size: "45%",
                                        pane: Pane(AlbumArt),
                                    ),
                                    (
                                        size: "25%",
                                        pane: Pane(Header),
                                    ),
                                    (
                                        size: "30%",
                                        pane: Pane(Lyrics),
                                    ),
                                ],
                            ),
                        ),
                        (
                            size: "70%",
                            borders: "ALL",
                            pane: Split(
                                direction: Vertical,
                                panes: [
                                    (
                                        size: "100%",
                                        pane: Pane(TabContent),
                                    ),
                                    (
                                        size: "1",
                                        borders: "NONE",
                                        pane: Pane(Tabs),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
            (
                size: "3",
                borders: "ALL",
                pane: Split(
                    direction: Horizontal,
                    panes: [
                        (
                            pane: Pane(Property(
                                content: [
                                    (
                                        kind: Property(Status(StateV2(
                                            playing_label: "  ",
                                            paused_label: "  ",
                                            stopped_label: "  ",
                                        ))),
                                    ),
                                ],
                                align: Left,
                            )),
                            size: "4",
                        ),
                        (
                            size: "100%",
                            pane: Pane(ProgressBar),
                        ),
                        (
                            pane: Pane(Property(
                                content: [
                                    (
                                        kind: Property(Status(Elapsed)),
                                    ),
                                    (
                                        kind: Text(" / "),
                                    ),
                                    (
                                        kind: Property(Status(Duration)),
                                    ),
                                    (
                                        kind: Group([
                                            (
                                                kind: Text(" ("),
                                            ),
                                            (
                                                kind: Property(Status(Bitrate)),
                                            ),
                                            (
                                                kind: Text(" kbps)"),
                                            ),
                                        ]),
                                    ),
                                ],
                                align: Right,
                            )),
                            size: "24",
                        ),
                    ],
                ),
            ),
        ],
    ),
    header: (
        rows: [
            (
                left: [
                ],
                center: [
                ],
                right: [
                ],
            ),
            (
                left: [
                ],
                center: [
                    (
                        kind: Property(Song(Title)),
                        style: (
                            fg: "{base0C}",
                            modifiers: "Bold",
                        ),
                        default: (
                            kind: Property(Song(Filename)),
                            style: (
                                fg: "{base0C}",
                                modifiers: "Bold",
                            ),
                        ),
                    ),
                ],
                right: [
                ],
            ),
            (
                left: [
                ],
                center: [
                    (
                        kind: Property(Song(Artist)),
                        style: (
                            fg: "{base06}",
                            modifiers: "Bold",
                        ),
                        default: (
                            kind: Text("Unknown Artist"),
                            style: (
                                fg: "{base06}",
                                modifiers: "Bold",
                            ),
                        ),
                    ),
                ],
                right: [
                ],
            ),
            (
                left: [
                ],
                center: [
                    (
                        kind: Property(Song(Album)),
                        style: (
                            fg: "{accent_alt}",
                        ),
                        default: (
                            kind: Text("Unknown Album"),
                            style: (
                                fg: "{accent_alt}",
                                modifiers: "Bold",
                            ),
                        ),
                    ),
                ],
                right: [
                ],
            ),
            (
                left: [
                    (
                        kind: Text("[ "),
                        style: (
                            fg: "{accent_alt}",
                        ),
                    ),
                    (
                        kind: Property(Status(RepeatV2(
                            on_label: " ",
                            off_label: " ",
                            on_style: (
                                fg: "{base06}",
                                modifiers: "Bold",
                            ),
                            off_style: (
                                fg: "{base04}",
                                modifiers: "Bold",
                            ),
                        ))),
                    ),
                    (
                        kind: Text(" | "),
                        style: (
                            fg: "{accent_alt}",
                        ),
                    ),
                    (
                        kind: Property(Status(RandomV2(
                            on_label: " ",
                            off_label: " ",
                            on_style: (
                                fg: "{base06}",
                                modifiers: "Bold",
                            ),
                            off_style: (
                                fg: "{base04}",
                                modifiers: "Bold",
                            ),
                        ))),
                    ),
                    (
                        kind: Text(" | "),
                        style: (
                            fg: "{accent_alt}",
                        ),
                    ),
                ],
                center: [
                    (
                        kind: Text("󰕾 "),
                        style: (
                            fg: "{accent_alt}",
                            modifiers: "Bold",
                        ),
                    ),
                    (
                        kind: Property(Status(Volume)),
                        style: (
                            fg: "{base06}",
                            modifiers: "Bold",
                        ),
                    ),
                    (
                        kind: Text("%"),
                        style: (
                            fg: "{accent_alt}",
                            modifiers: "Bold",
                        ),
                    ),
                ],
                right: [
                    (
                        kind: Text(" | "),
                        style: (
                            fg: "{accent_alt}",
                        ),
                    ),
                    (
                        kind: Property(Status(ConsumeV2(
                            on_label: "󰮯 ",
                            off_label: "󰮯 ",
                            oneshot_label: "󰮯 󰇊",
                            on_style: (
                                fg: "{base06}",
                                modifiers: "Bold",
                            ),
                            off_style: (
                                fg: "{base04}",
                                modifiers: "Bold",
                            ),
                        ))),
                    ),
                    (
                        kind: Text(" | "),
                        style: (
                            fg: "{accent_alt}",
                        ),
                    ),
                    (
                        kind: Property(Status(SingleV2(
                            on_label: "󰎤 ",
                            off_label: "󰎦 ",
                            oneshot_label: "󰇊 ",
                            off_oneshot_label: "󱅊 ",
                            on_style: (
                                fg: "{base06}",
                                modifiers: "Bold",
                            ),
                            off_style: (
                                fg: "{base04}",
                                modifiers: "Bold",
                            ),
                        ))),
                    ),
                    (
                        kind: Text(" ]"),
                        style: (
                            fg: "{accent_alt}",
                        ),
                    ),
                ],
            ),
        ],
    ),
    browser_song_format: [
        (
            kind: Group([
                (
                    kind: Property(Track),
                ),
                (
                    kind: Text(" "),
                ),
            ]),
        ),
        (
            kind: Group([
                (
                    kind: Property(Artist),
                ),
                (
                    kind: Text(" - "),
                ),
                (
                    kind: Property(Title),
                ),
            ]),
            default: (
                kind: Property(Filename),
            ),
        ),
    ],
)
