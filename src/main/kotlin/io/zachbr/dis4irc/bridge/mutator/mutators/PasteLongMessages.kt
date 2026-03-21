/*
 * This file is part of Dis4IRC.
 *
 * Copyright (c) Dis4IRC contributors
 *
 * MIT License
 */

package io.zachbr.dis4irc.bridge.mutator.mutators

import io.zachbr.dis4irc.bridge.Bridge
import io.zachbr.dis4irc.bridge.message.DiscordSource
import io.zachbr.dis4irc.bridge.message.PlatformMessage
import io.zachbr.dis4irc.bridge.mutator.api.Mutator
import io.zachbr.dis4irc.util.countSubstring
import org.spongepowered.configurate.CommentedConfigurationNode
import kotlin.math.min

private const val FENCED_BLOCK = "```"

class PasteLongMessages(val bridge: Bridge, config: CommentedConfigurationNode) : Mutator {

    private var maxNewlines: Int = 4
    private var maxMsgLength: Int = 450

    init {
        val msgNewlineCount = config.node("max-new-lines")
        if (msgNewlineCount.virtual()) {
            msgNewlineCount.set(maxNewlines)
        }

        val msgLengthNode = config.node("max-message-length")
        if (msgLengthNode.virtual()) {
            msgLengthNode.set(maxMsgLength)
        }

        maxNewlines = msgNewlineCount.int
        maxMsgLength = msgLengthNode.int
    }

    override fun mutate(message: PlatformMessage): Mutator.LifeCycle {
        val msgContents = message.contents

        // we only need to truncate discord messages
        if (message.source !is DiscordSource) {
            return Mutator.LifeCycle.CONTINUE
        }

        var shouldTruncate = false

        if (countSubstring(msgContents, "\n") > maxNewlines) {
            shouldTruncate = true
        }

        if (countSubstring(msgContents, FENCED_BLOCK) >= 2) {
            shouldTruncate = true
        }

        if (msgContents.length > maxMsgLength) {
            shouldTruncate = true
        }

        if (!shouldTruncate) {
            return Mutator.LifeCycle.CONTINUE
        }

        // Strip code fences, collapse to single line, and truncate
        val cleaned = msgContents
            .replace(FENCED_BLOCK, "")
            .replace("`", "")
            .replace("\n", " ")

        val maxLength = min(maxMsgLength, cleaned.length)
        message.contents = cleaned.substring(0, maxLength) + "..."

        return Mutator.LifeCycle.CONTINUE
    }
}
