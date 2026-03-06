import { useBackend } from "../backend";
import { Box, Button, Flex, Section, Stack } from "../components";
import { Window } from "../layouts";

const CHAPTER_COLORS = {
  1: "#FFD700",
  2: "#C0C0C0",
  3: "#8B0000",
  4: "#8B4513",
  5: "#FF4500",
  6: "#4682B4",
  7: "#708090",
};

export const ProsthetiChapterSelect = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    already_selected = false,
    selected_chapter = 1,
    highest_completed = 0,
    player_name = "",
    chapters = [],
  } = data || {};

  return (
    <Window
      title="Prostheti Innovations"
      width={480}
      height={560}>
      <Window.Content>
        <Section>
          <Box textAlign="center" mb={1}>
            <Box
              fontSize="16px"
              bold
              style={{
                fontFamily: "Baskerville, Georgia, serif",
                letterSpacing: "2px",
              }}>
              PROSTHETI INNOVATIONS
            </Box>
            <Box
              fontSize="12px"
              color="label"
              style={{ fontFamily: "Baskerville, Georgia, serif" }}>
              Campaign Chapter Select
            </Box>
          </Box>

          {already_selected ? (
            <AlreadySelectedView selectedChapter={selected_chapter} />
          ) : (
            <ChapterListView
              chapters={chapters}
              highestCompleted={highest_completed}
              playerName={player_name}
              act={act}
            />
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

const AlreadySelectedView = (props) => {
  const { selectedChapter } = props;
  return (
    <Box textAlign="center" mt={4}>
      <Box fontSize="14px" color="average" bold>
        A chapter has already been selected this round.
      </Box>
      <Box fontSize="12px" color="label" mt={2}>
        Currently on Chapter {selectedChapter}.
      </Box>
    </Box>
  );
};

const ChapterListView = (props) => {
  const { chapters, highestCompleted, playerName, act } = props;

  return (
    <>
      <Box color="label" fontSize="11px" mb={1}>
        Selecting a chapter will set the starting point for all players this
        round.
      </Box>
      <Section title="Available Chapters" scrollable scrollableHorizontal={false}>
        <Stack vertical>
          {chapters.map((chapter) => (
            <Stack.Item key={chapter.number}>
              <ChapterCard
                chapter={chapter}
                act={act}
              />
            </Stack.Item>
          ))}
        </Stack>
      </Section>
      <Box
        textAlign="center"
        fontSize="11px"
        color="label"
        mt={1}>
        Progress for: {playerName}
        {highestCompleted > 0
          ? ` (Completed through Chapter ${highestCompleted})`
          : " (New player)"}
      </Box>
    </>
  );
};

const ChapterCard = (props) => {
  const { chapter, act } = props;
  const color = CHAPTER_COLORS[chapter.number] || "#FFFFFF";
  const isLocked = !chapter.unlocked;

  return (
    <Box
      style={{
        borderLeft: `3px solid ${isLocked ? "#333" : color}`,
        padding: "8px 12px",
        marginBottom: "4px",
        opacity: isLocked ? 0.35 : 1,
        backgroundColor: "rgba(0, 0, 0, 0.2)",
      }}>
      <Flex align="center">
        <Flex.Item
          width="30px"
          textAlign="center"
          fontSize="16px"
          bold
          color={isLocked ? "label" : "default"}>
          {chapter.number}
        </Flex.Item>
        <Flex.Item grow={1} ml={1}>
          <Box>
            <Box inline fontSize="13px" bold>
              {chapter.title}
            </Box>
            {chapter.is_new && (
              <Box
                inline
                ml={1}
                px={1}
                fontSize="10px"
                bold
                style={{
                  backgroundColor: color,
                  color: "#000",
                  borderRadius: "3px",
                }}>
                NEW
              </Box>
            )}
          </Box>
          {!isLocked && chapter.subtitle && (
            <Box fontSize="11px" style={{ color: color }}>
              {chapter.subtitle}
            </Box>
          )}
          {!isLocked && chapter.description && (
            <Box fontSize="10px" color="label" mt={0.5}>
              {chapter.description}
            </Box>
          )}
          {isLocked && (
            <Box fontSize="10px" color="label">
              (locked)
            </Box>
          )}
        </Flex.Item>
        <Flex.Item width="70px" textAlign="right">
          {!isLocked ? (
            <Button
              content="Select"
              onClick={() =>
                act("select", { chapter: chapter.number })
              }
            />
          ) : (
            <Box fontSize="14px" color="label">
              &#128274;
            </Box>
          )}
        </Flex.Item>
      </Flex>
    </Box>
  );
};
