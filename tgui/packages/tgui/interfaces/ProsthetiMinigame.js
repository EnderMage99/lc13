import { useBackend, useSharedState } from '../backend';
import {
  Box,
  Button,
  Flex,
  NumberInput,
  Section,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';

// =============================================
// Pentagon Chart Constants
// =============================================

const ATTRIBUTE_ORDER = [
  'lethality',
  'endurance',
  'agility',
  'control',
  'efficiency',
];

// Pentagon vertex angles (starting from top, clockwise)
const ANGLES = ATTRIBUTE_ORDER.map(
  (_, i) => -Math.PI / 2 + (i * 2 * Math.PI) / 5
);

// =============================================
// Pentagon Chart SVG Component
// =============================================

const PentagonChart = (props) => {
  const {
    values = {},
    maxValue = 10,
    size = 200,
    color = 'rgba(255,165,0,0.6)',
    strokeColor = 'rgba(255,165,0,0.9)',
    overlayValues = null,
    overlayColor = 'rgba(255,255,255,0.3)',
    overlayStrokeColor = 'rgba(255,255,255,0.8)',
    attributeNames = {},
    attributeColors = {},
    showLabels = true,
    showValues = true,
  } = props;

  const cx = size / 2;
  const cy = size / 2;
  const radius = size * 0.38;

  const getPoint = (value, angleIndex) => {
    const scale = Math.min(value / maxValue, 1.0);
    return {
      x: cx + scale * radius * Math.cos(ANGLES[angleIndex]),
      y: cy + scale * radius * Math.sin(ANGLES[angleIndex]),
    };
  };

  const getPolygonPoints = (vals) => {
    return ATTRIBUTE_ORDER.map((attr, i) => {
      const pt = getPoint(vals[attr] || 0, i);
      return `${pt.x},${pt.y}`;
    }).join(' ');
  };

  // Grid rings at 25%, 50%, 75%, 100%
  const gridRings = [0.25, 0.5, 0.75, 1.0].map((scale) => {
    const points = ATTRIBUTE_ORDER.map((_, i) => {
      const x = cx + scale * radius * Math.cos(ANGLES[i]);
      const y = cy + scale * radius * Math.sin(ANGLES[i]);
      return `${x},${y}`;
    }).join(' ');
    return points;
  });

  // Axis lines from center to each vertex
  const axisLines = ATTRIBUTE_ORDER.map((_, i) => ({
    x2: cx + radius * Math.cos(ANGLES[i]),
    y2: cy + radius * Math.sin(ANGLES[i]),
  }));

  // Label positions (slightly beyond the pentagon)
  const labelRadius = radius + 22;

  return (
    <svg
      viewBox={`0 0 ${size} ${size}`}
      width={size}
      height={size}
      style={{ display: 'block' }}>
      {/* Grid rings */}
      {gridRings.map((points, i) => (
        <polygon
          key={'grid-' + i}
          points={points}
          fill="none"
          stroke="rgba(255,255,255,0.1)"
          strokeWidth="0.5"
        />
      ))}

      {/* Axis lines */}
      {axisLines.map((line, i) => (
        <line
          key={'axis-' + i}
          x1={cx}
          y1={cy}
          x2={line.x2}
          y2={line.y2}
          stroke="rgba(255,255,255,0.1)"
          strokeWidth="0.5"
        />
      ))}

      {/* Client overlay polygon (white outline, revealed in results) */}
      {overlayValues && (
        <polygon
          points={getPolygonPoints(overlayValues)}
          fill={overlayColor}
          stroke={overlayStrokeColor}
          strokeWidth="2"
          strokeDasharray="4,2"
        />
      )}

      {/* Player polygon (orange fill) */}
      <polygon
        points={getPolygonPoints(values)}
        fill={color}
        stroke={strokeColor}
        strokeWidth="1.5"
      />

      {/* Labels at each vertex */}
      {showLabels &&
        ATTRIBUTE_ORDER.map((attr, i) => {
          const lx = cx + labelRadius * Math.cos(ANGLES[i]);
          const ly = cy + labelRadius * Math.sin(ANGLES[i]);
          const name = attributeNames[attr] || attr;
          const val = values[attr] || 0;
          const attrColor = attributeColors[attr] || '#FFFFFF';

          return (
            <text
              key={'label-' + attr}
              x={lx}
              y={ly}
              fill={attrColor}
              fontSize="9"
              fontWeight="bold"
              textAnchor="middle"
              dominantBaseline="middle">
              {name}
              {showValues ? ` ${val}` : ''}
            </text>
          );
        })}
    </svg>
  );
};

// =============================================
// Attribute Modifier Display
// =============================================

const AttributeModifiers = (props) => {
  const { attributes = {}, attributeColors = {} } = props;

  if (!attributes || !Object.keys(attributes).length) {
    return null;
  }

  return (
    <Box as="span" fontSize="10px">
      {Object.keys(attributes).map((attr, i) => {
        const val = attributes[attr];
        if (val === 0) {
          return null;
        }
        const abbr = attr.substring(0, 2).toUpperCase();
        const color =
          val > 0
            ? attributeColors[attr] || '#44AA44'
            : '#CC4444';

        return (
          <Box as="span" key={attr} color={color} mr={0.5}>
            {abbr}
            {val > 0 ? '+' : ''}
            {val}
          </Box>
        );
      })}
    </Box>
  );
};

// =============================================
// Main Component
// =============================================

export const ProsthetiMinigame = (props, context) => {
  const { data = {}, act } = useBackend(context);

  if (data.no_game) {
    return (
      <Window title="Augment Design Terminal" width={480} height={300}>
        <Window.Content>
          <Section>
            <Box textAlign="center" mt={4}>
              <Box
                fontSize="16px"
                bold
                mb={2}
                style={{ fontFamily: 'Baskerville, Georgia, serif' }}>
                Prostheti Innovations
              </Box>
              <Box color="label" mb={3}>
                Augment Design Challenge
              </Box>
              <Box color="grey" mb={3} italic>
                Design augments for profit. Read client needs, shape your
                pentagon, and prove your worth.
              </Box>
              <Button
                content="Begin Challenge"
                icon="play"
                color="good"
                onClick={() => act('start_game')}
              />
            </Box>
          </Section>
        </Window.Content>
      </Window>
    );
  }

  const phase = data.phase;

  let width = 560;
  let height = 620;
  if (phase === 2) {
    width = 820;
    height = 700;
  } else if (phase === 4) {
    width = 640;
    height = 650;
  }

  return (
    <Window
      title="Augment Design Terminal"
      width={width}
      height={height}>
      <Window.Content scrollable>
        {phase === 1 && <BriefingPhase />}
        {phase === 2 && <DesignPhase />}
        {phase === 3 && <ResultsPhase />}
        {phase === 4 && <ShopPhase />}
        {phase === 5 && <FinalPhase />}
      </Window.Content>
    </Window>
  );
};

// =============================================
// Phase 1: Morning Briefing
// =============================================

const BriefingPhase = (props, context) => {
  const { data = {}, act } = useBackend(context);
  const {
    current_day = 1,
    total_days = 3,
    designs_per_day = 3,
    day_clients = [],
    trending_tags = [],
    oversaturated_tags = [],
    tag_colors = {},
    price_changes = [],
  } = data;

  return (
    <Box>
      <Section
        title={
          <span style={{ fontFamily: 'Baskerville, Georgia, serif' }}>
            Day {current_day} of {total_days} — Morning Briefing
          </span>
        }>
        <Box bold mb={1} fontSize="12px">
          Today&apos;s Clients ({designs_per_day} designs):
        </Box>
        {/* Client Cards */}
        {day_clients.map((client, i) => (
          <Box
            key={i}
            p={1.5}
            mb={1}
            style={{
              border: '1px solid rgba(255,255,255,0.15)',
              borderRadius: '4px',
              background: 'rgba(255,255,255,0.03)',
            }}>
            <Box fontSize="13px" bold mb={0.5}>
              #{i + 1}: {client.name}
            </Box>
            <Box
              color="label"
              mb={0.5}
              italic
              p={0.5}
              style={{
                background: 'rgba(255,255,255,0.03)',
                borderLeft: '3px solid rgba(255,215,0,0.4)',
                borderRadius: '2px',
              }}>
              &ldquo;{client.hint}&rdquo;
            </Box>
            <Box color="grey" fontSize="11px" mb={0.5}>
              Preferred Rank: {client.rank_min}–{client.rank_max}
            </Box>
            {client.required_tags
              && client.required_tags.length > 0 && (
              <Box fontSize="11px">
                <Box as="span" bold>
                  Required:{' '}
                </Box>
                {client.required_tags.map((tag) => (
                  <TagBadge
                    key={tag}
                    tag={tag}
                    colors={tag_colors}
                  />
                ))}
              </Box>
            )}
          </Box>
        ))}
        <Box color="grey" fontSize="10px" italic mt={1}>
          Effects used in one design cannot be reused in
          another design today.
        </Box>
      </Section>

      {/* Market Board */}
      <Section title="Market Board">
        <Flex mb={2}>
          <Flex.Item grow={1} mr={1}>
            <Box bold mb={1} color="green">
              Trending (+8% sell bonus):
            </Box>
            {trending_tags.map((tag) => (
              <TagBadge key={tag} tag={tag} colors={tag_colors} />
            ))}
          </Flex.Item>
          <Flex.Item grow={1}>
            <Box bold mb={1} color="red">
              Oversaturated (-6% sell penalty):
            </Box>
            {oversaturated_tags.map((tag) => (
              <TagBadge key={tag} tag={tag} colors={tag_colors} />
            ))}
          </Flex.Item>
        </Flex>

        {/* Price Changes */}
        {price_changes.length > 0 && (
          <Box>
            <Box bold mb={1}>
              Price Changes:
            </Box>
            <Box maxHeight="120px" overflowY="auto">
              {price_changes.map((change, i) => (
                <Box key={i} fontSize="11px" mb={0.5}>
                  <Box
                    as="span"
                    color={change.type === 'sale' ? 'green' : 'red'}>
                    {change.type === 'sale'
                      ? `SALE -${change.percent}%`
                      : `MARKUP +${change.percent}%`}
                  </Box>{' '}
                  {change.name}
                </Box>
              ))}
            </Box>
          </Box>
        )}
      </Section>

      <Box textAlign="center" mt={2}>
        <Button
          content="Begin Designing"
          icon="pencil-alt"
          color="good"
          fontSize="13px"
          onClick={() => act('begin_designing')}
        />
      </Box>
    </Box>
  );
};

// =============================================
// Phase 2: Design Workspace
// =============================================

const DesignPhase = (props, context) => {
  const { data = {}, act } = useBackend(context);
  const [searchFilter, setSearchFilter] = useSharedState(
    context,
    'search',
    ''
  );
  const [activeTab, setActiveTab] = useSharedState(
    context,
    'effectTab',
    'all'
  );

  const {
    current_day = 1,
    current_design_num = 1,
    designs_per_day = 4,
    effects = [],
    forms = [],
    selected_form = '',
    selected_rank = 1,
    selected_effects = [],
    selected_details = [],
    remaining_ep = 0,
    current_cost = 0,
    max_rank = 5,
    trending_tags = [],
    oversaturated_tags = [],
    tag_colors = {},
    client_name = '',
    client_hint = '',
    client_rank_min = 1,
    client_rank_max = 5,
    client_required_tags = [],
    current_attributes = {},
    attribute_names = {},
    attribute_colors = {},
  } = data;

  const usedEffectsToday = data.used_effects_today || [];

  // Attribute abbreviation map for search
  const ATTR_ABBREVS = {
    le: 'lethality',
    en: 'endurance',
    ag: 'agility',
    co: 'control',
    ef: 'efficiency',
    lethality: 'lethality',
    endurance: 'endurance',
    agility: 'agility',
    control: 'control',
    efficiency: 'efficiency',
  };

  // Filter effects
  let filteredEffects = effects;
  if (searchFilter) {
    const lowerSearch = searchFilter.toLowerCase().trim();
    filteredEffects = effects.filter((e) => {
      // Match name
      if (e.name.toLowerCase().includes(lowerSearch)) {
        return true;
      }
      // Match description
      if (e.desc && e.desc.toLowerCase().includes(lowerSearch)) {
        return true;
      }
      // Match tags
      if (
        e.tags
        && e.tags.some((t) => t.toLowerCase().includes(lowerSearch))
      ) {
        return true;
      }
      // Match attribute keys/abbreviations
      if (e.attributes) {
        const matchedAttr = ATTR_ABBREVS[lowerSearch];
        if (matchedAttr && e.attributes[matchedAttr]) {
          return true;
        }
        // Also partial match attribute names
        for (const attrKey of Object.keys(e.attributes)) {
          if (
            e.attributes[attrKey] !== 0
            && attrKey.includes(lowerSearch)
          ) {
            return true;
          }
        }
      }
      // Match +/- attribute searches like "le+" or "ag-"
      const modMatch = lowerSearch.match(/^(\w+)([+-])$/);
      if (modMatch && e.attributes) {
        const attr = ATTR_ABBREVS[modMatch[1]];
        const wantPositive = modMatch[2] === '+';
        if (attr && e.attributes[attr]) {
          return wantPositive
            ? e.attributes[attr] > 0
            : e.attributes[attr] < 0;
        }
      }
      return false;
    });
  }
  if (activeTab !== 'all') {
    filteredEffects = filteredEffects.filter(
      (e) => e.tags && e.tags.includes(activeTab)
    );
  }

  // Check required tags
  const designTags = {};
  selected_details.forEach((eff) => {
    if (eff.tags) {
      eff.tags.forEach((tag) => {
        designTags[tag] = (designTags[tag] || 0) + 1;
      });
    }
  });

  const canSubmit = selected_form && selected_effects.length > 0;

  return (
    <Flex>
      {/* Left Panel — Pentagon + Client Reference */}
      <Flex.Item width="260px" mr={1}>
        <Section
          title={
            'Day ' + current_day
            + ' \u2014 Design ' + current_design_num
            + '/' + designs_per_day
            + ': ' + client_name
          }>
          {/* Live Pentagon Chart */}
          <Box textAlign="center" mb={1}>
            <PentagonChart
              values={current_attributes}
              maxValue={12}
              size={220}
              attributeNames={attribute_names}
              attributeColors={attribute_colors}
              showValues
            />
          </Box>

          {/* Client Reference */}
          <Box
            p={1}
            mb={1}
            style={{
              border: '1px solid rgba(255,255,255,0.1)',
              borderRadius: '3px',
              background: 'rgba(255,255,255,0.02)',
            }}>
            <Box bold fontSize="11px" mb={0.5}>
              {client_name}
            </Box>
            <Box color="grey" fontSize="10px" italic mb={0.5}>
              &ldquo;{client_hint}&rdquo;
            </Box>
            <Box fontSize="10px" mb={0.5}>
              Rank: {client_rank_min}–{client_rank_max}
              {(selected_rank < client_rank_min ||
                selected_rank > client_rank_max) && (
                <Box as="span" color="red" ml={0.5}>
                  (mismatch!)
                </Box>
              )}
            </Box>
            {client_required_tags.length > 0 && (
              <Box fontSize="10px">
                Req:{' '}
                {client_required_tags.map((tag) => (
                  <Box as="span" key={tag} mr={0.5}>
                    <TagBadge tag={tag} colors={tag_colors} small />
                    {designTags[tag] ? (
                      <Box as="span" color="green">
                        {' '}
                        ✓
                      </Box>
                    ) : (
                      <Box as="span" color="red">
                        {' '}
                        ✗
                      </Box>
                    )}
                  </Box>
                ))}
              </Box>
            )}
            <Box fontSize="10px" mt={0.5}>
              <Box as="span" color="green">
                Trend:{' '}
              </Box>
              {trending_tags.map((tag) => (
                <TagBadge
                  key={tag}
                  tag={tag}
                  colors={tag_colors}
                  small
                />
              ))}
            </Box>
            <Box fontSize="10px">
              <Box as="span" color="red">
                Over:{' '}
              </Box>
              {oversaturated_tags.map((tag) => (
                <TagBadge
                  key={tag}
                  tag={tag}
                  colors={tag_colors}
                  small
                />
              ))}
            </Box>
          </Box>
        </Section>

        {/* Your Design */}
        <Section title="Your Design">
          <Box mb={1}>
            <Box bold fontSize="11px" mb={0.5}>
              Form:
            </Box>
            {forms.map((form) => (
              <Button
                key={form.id}
                content={form.name}
                selected={selected_form === form.id}
                onClick={() => act('set_form', { form_id: form.id })}
                mb={0.5}
              />
            ))}
          </Box>
          <Box mb={1}>
            <Box bold fontSize="11px" mb={0.5}>
              Rank:
            </Box>
            <NumberInput
              value={selected_rank}
              minValue={1}
              maxValue={max_rank}
              step={1}
              width="50px"
              onChange={(e, value) => act('set_rank', { rank: value })}
            />
          </Box>
          <Box mb={1}>
            <Box bold fontSize="11px">
              EP: {remaining_ep} remaining
            </Box>
            <Box bold fontSize="11px">
              Cost: {current_cost} ahn
            </Box>
          </Box>

          {/* Selected Effects */}
          {selected_details.map((eff, i) => (
            <Box
              key={i}
              mb={0.5}
              p={0.5}
              style={{
                background: 'rgba(255,255,255,0.05)',
                borderRadius: '2px',
              }}>
              <Flex align="center">
                <Flex.Item grow={1}>
                  <Box fontSize="11px">{eff.name}</Box>
                  <Box fontSize="10px">
                    <AttributeModifiers
                      attributes={eff.attributes}
                      attributeColors={attribute_colors}
                    />
                    <Box as="span" color="grey" ml={0.5}>
                      {eff.current_ahn_cost} ahn
                    </Box>
                  </Box>
                </Flex.Item>
                <Flex.Item>
                  <Button
                    icon="times"
                    color="bad"
                    onClick={() => act('remove_effect', { index: i + 1 })}
                  />
                </Flex.Item>
              </Flex>
            </Box>
          ))}

          {!selected_details.length && (
            <Box color="grey" italic fontSize="11px">
              No effects added yet.
            </Box>
          )}

          <Box mt={2} textAlign="center">
            <Button
              content="Submit Design"
              icon="check"
              color="good"
              disabled={!canSubmit}
              onClick={() => act('submit_design')}
            />
          </Box>
        </Section>
      </Flex.Item>

      {/* Right Panel — Effect Browser */}
      <Flex.Item grow={1}>
        <Section title="Available Effects">
          {/* Search */}
          <Box mb={1}>
            <input
              type="text"
              placeholder="Search effects..."
              value={searchFilter}
              onChange={(e) => setSearchFilter(e.target.value)}
              style={{
                width: '100%',
                padding: '4px 8px',
                background: 'rgba(0,0,0,0.3)',
                border: '1px solid rgba(255,255,255,0.15)',
                borderRadius: '2px',
                color: '#fff',
                fontSize: '12px',
              }}
            />
          </Box>

          {/* Tag Filter Tabs */}
          <Tabs mb={1}>
            <Tabs.Tab
              selected={activeTab === 'all'}
              onClick={() => setActiveTab('all')}>
              All
            </Tabs.Tab>
            {[
              'defensive',
              'offensive',
              'healing',
              'bleed',
              'overheat',
              'tremor',
              'on-kill',
              'support',
              'risky',
            ].map((tag) => (
              <Tabs.Tab
                key={tag}
                selected={activeTab === tag}
                onClick={() => setActiveTab(tag)}>
                {tag}
              </Tabs.Tab>
            ))}
          </Tabs>

          {/* Effect List */}
          <Box maxHeight="480px" overflowY="auto">
            {filteredEffects.map((eff) => (
              <EffectRow
                key={eff.id}
                effect={eff}
                tag_colors={tag_colors}
                attribute_colors={attribute_colors}
                trending_tags={trending_tags}
                oversaturated_tags={oversaturated_tags}
                locked={usedEffectsToday.includes(eff.id)}
              />
            ))}
            {!filteredEffects.length && (
              <Box color="grey" italic textAlign="center" mt={2}>
                No effects match your filter.
              </Box>
            )}
          </Box>
        </Section>
      </Flex.Item>
    </Flex>
  );
};

// Single effect row in the browser
const EffectRow = (props, context) => {
  const { act } = useBackend(context);
  const {
    effect,
    tag_colors = {},
    attribute_colors = {},
    trending_tags = [],
    oversaturated_tags = [],
    locked = false,
  } = props;

  // Check if any tag is trending or oversaturated
  const hasTrending =
    effect.tags
    && effect.tags.some((t) => trending_tags.includes(t));
  const hasOversaturated =
    effect.tags
    && effect.tags.some((t) => oversaturated_tags.includes(t));

  let borderColor = 'rgba(255,255,255,0.08)';
  if (locked) {
    borderColor = 'rgba(128,128,128,0.3)';
  } else if (hasTrending) {
    borderColor = 'rgba(0,200,0,0.3)';
  } else if (hasOversaturated) {
    borderColor = 'rgba(200,0,0,0.3)';
  }

  return (
    <Box
      mb={0.5}
      p={1}
      style={{
        border: `1px solid ${borderColor}`,
        borderRadius: '3px',
        background: locked
          ? 'rgba(128,128,128,0.08)'
          : 'rgba(255,255,255,0.02)',
        opacity: locked ? 0.45 : 1,
      }}>
      <Flex align="center">
        <Flex.Item grow={1}>
          <Box bold fontSize="12px">
            {effect.special && (
              <Box
                as="span"
                color="gold"
                mr={0.5}
                title={
                  'While ' + effect.special.condition
                  + ' >= ' + effect.special.threshold
                  + ': bonus'
                }>
                ★
              </Box>
            )}
            {effect.name}
            {effect.sale_percent > 0 && (
              <Box as="span" color="green" ml={1} fontSize="10px">
                SALE -{effect.sale_percent}%
              </Box>
            )}
            {effect.markup_percent > 0 && (
              <Box as="span" color="red" ml={1} fontSize="10px">
                +{effect.markup_percent}%
              </Box>
            )}
          </Box>
          <Box mb={0.5}>
            <AttributeModifiers
              attributes={effect.attributes}
              attributeColors={attribute_colors}
            />
            {effect.special && (
              <Box as="span" fontSize="9px" color="gold" ml={0.5}>
                [{effect.special.condition.substring(0, 2).toUpperCase()}
                &gt;{effect.special.threshold}→
                {Object.keys(effect.special.bonus)
                  .map((attr) => {
                    const val = effect.special.bonus[attr];
                    return `${attr.substring(0, 2).toUpperCase()}+${val}`;
                  })
                  .join(',')}
                ]
              </Box>
            )}
          </Box>
          <Flex align="center">
            <Flex.Item mr={1}>
              <Box fontSize="10px">
                EP: {effect.ep_cost} |{' '}
                {effect.current_ahn_cost !== effect.ahn_cost ? (
                  <>
                    <Box as="span" style={{ textDecoration: 'line-through' }}>
                      {effect.ahn_cost}
                    </Box>{' '}
                    <Box
                      as="span"
                      color={
                        effect.current_ahn_cost < effect.ahn_cost
                          ? 'green'
                          : 'red'
                      }>
                      {effect.current_ahn_cost}
                    </Box>
                  </>
                ) : (
                  effect.ahn_cost
                )}{' '}
                ahn
                {effect.repeatable > 1 && ` | x${effect.repeatable}`}
              </Box>
            </Flex.Item>
            <Flex.Item>
              {effect.tags &&
                effect.tags.map((tag) => (
                  <TagBadge key={tag} tag={tag} colors={tag_colors} small />
                ))}
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          {locked ? (
            <Button
              icon="lock"
              color="grey"
              disabled
              tooltip="Used in a previous design today"
            />
          ) : (
            <Button
              icon="plus"
              onClick={() =>
                act('add_effect', { effect_id: effect.id })}
            />
          )}
        </Flex.Item>
      </Flex>
    </Box>
  );
};

// =============================================
// Phase 3: End-of-Day Results
// =============================================

const ResultsPhase = (props, context) => {
  const { data = {}, act } = useBackend(context);
  const {
    current_day = 1,
    total_days = 3,
    day_designs = [],
    day_profit = 0,
    total_profit = 0,
    is_last_day = false,
    attribute_names = {},
    attribute_colors = {},
  } = data;

  return (
    <Box>
      <Section
        title={
          <span style={{ fontFamily: 'Baskerville, Georgia, serif' }}>
            Day {current_day} — Results
          </span>
        }>
        {day_designs.map((design, i) => (
          <Box
            key={i}
            mb={2}
            p={1.5}
            style={{
              border: '1px solid rgba(255,255,255,0.1)',
              borderRadius: '4px',
              background: 'rgba(255,255,255,0.02)',
            }}>
            <Box bold mb={1}>
              Design #{i + 1}: {design.client_name} — {design.form}
              {' '}(Rank {design.rank})
            </Box>

            {/* Pentagon Overlay — player (orange) vs client (white) */}
            <Flex mb={1}>
              <Flex.Item mr={2}>
                <PentagonChart
                  values={design.player_attributes || {}}
                  maxValue={12}
                  size={180}
                  overlayValues={design.client_attributes || null}
                  attributeNames={attribute_names}
                  attributeColors={attribute_colors}
                  showValues={false}
                />
              </Flex.Item>
              <Flex.Item grow={1}>
                {/* Per-axis breakdown */}
                <Box bold mb={0.5} fontSize="12px">
                  Attribute Overlap
                </Box>
                <Table fontSize="11px">
                  {design.axis_breakdown &&
                    design.axis_breakdown.map((axis, j) => (
                      <Table.Row key={j}>
                        <Table.Cell
                          color={
                            attribute_colors[axis.attr] || 'label'
                          }>
                          {attribute_names[axis.attr] || axis.attr}:
                        </Table.Cell>
                        <Table.Cell textAlign="center">
                          {axis.player} / {axis.client}
                        </Table.Cell>
                        <Table.Cell
                          textAlign="right"
                          color={axis.covered ? 'green' : 'red'}>
                          {axis.covered
                            ? `✓ +${axis.diff}`
                            : `✗ ${axis.diff}`}
                        </Table.Cell>
                      </Table.Row>
                    ))}
                </Table>
                <Box
                  mt={1}
                  bold
                  fontSize="14px"
                  color={
                    design.overlap >= 1.0
                      ? 'green'
                      : design.overlap >= 0.7
                        ? '#DDAA00'
                        : 'red'
                  }>
                  Overlap: {Math.round((design.overlap || 0) * 100)}%
                </Box>
              </Flex.Item>
            </Flex>

            {/* Profit Breakdown */}
            <Table fontSize="11px">
              <Table.Row>
                <Table.Cell color="label">Material Cost:</Table.Cell>
                <Table.Cell textAlign="right" color="red">
                  -{design.material_cost} ahn
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell color="label">Base Sell Value:</Table.Cell>
                <Table.Cell textAlign="right">
                  {design.base_sell} ahn
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell color="label">
                  Overlap ×{((design.overlap || 0) * 100).toFixed(0)}%:
                </Table.Cell>
                <Table.Cell textAlign="right">
                  {design.overlap_sell} ahn
                </Table.Cell>
              </Table.Row>
              {design.breakdown &&
                design.breakdown.map((item, j) => (
                  <Table.Row key={j}>
                    <Table.Cell
                      color={item.positive ? 'green' : 'red'}
                      pl={2}>
                      {item.label}:
                    </Table.Cell>
                    <Table.Cell
                      textAlign="right"
                      color={item.positive ? 'green' : 'red'}>
                      {item.value > 0 ? '+' : ''}
                      {item.value} ahn
                    </Table.Cell>
                  </Table.Row>
                ))}
            </Table>

            {/* Profit */}
            <Box
              mt={1}
              pt={1}
              bold
              style={{ borderTop: '1px solid rgba(255,255,255,0.1)' }}>
              Profit:{' '}
              <Box as="span" color={design.profit >= 0 ? 'good' : 'bad'}>
                {design.profit >= 0 ? '+' : ''}
                {design.profit} ahn
              </Box>
            </Box>
          </Box>
        ))}

        {/* Day Summary */}
        <Box
          p={1.5}
          style={{
            border: '2px solid rgba(255,215,0,0.3)',
            borderRadius: '4px',
            background: 'rgba(255,215,0,0.05)',
          }}>
          <Flex justify="space-between">
            <Flex.Item bold>Day {current_day} Total:</Flex.Item>
            <Flex.Item bold color={day_profit >= 0 ? 'good' : 'bad'}>
              {day_profit >= 0 ? '+' : ''}
              {day_profit} ahn
            </Flex.Item>
          </Flex>
          <Flex justify="space-between" mt={0.5}>
            <Flex.Item color="label">Running Total:</Flex.Item>
            <Flex.Item color={total_profit >= 0 ? 'good' : 'bad'}>
              {total_profit >= 0 ? '+' : ''}
              {total_profit} ahn
            </Flex.Item>
          </Flex>
        </Box>

        <Box textAlign="center" mt={2}>
          <Button
            content={
              is_last_day
                ? 'View Final Score'
                : `Continue to Day ${current_day + 1}`
            }
            icon={is_last_day ? 'trophy' : 'arrow-right'}
            color="good"
            fontSize="13px"
            onClick={() => act('next_day')}
          />
        </Box>
      </Section>
    </Box>
  );
};

// =============================================
// Phase 4: Workshop Shop
// =============================================

const ShopPhase = (props, context) => {
  const { data = {}, act } = useBackend(context);
  const {
    total_profit = 0,
    workshops = [],
    tag_colors = {},
    attribute_names = {},
    attribute_colors = {},
    current_day = 1,
    total_days = 3,
  } = data;

  return (
    <Box>
      <Section
        title={
          <span
            style={{
              fontFamily: 'Baskerville, Georgia, serif',
            }}>
            Workshop Partnerships
          </span>
        }>
        <Box mb={1} fontSize="12px">
          Invest your profits in workshop partnerships
          to unlock exclusive augment effects for
          future designs.
        </Box>
        <Box bold mb={2} fontSize="13px">
          Available Budget:{' '}
          <Box
            as="span"
            color={total_profit >= 0 ? 'good' : 'bad'}>
            {total_profit} ahn
          </Box>
        </Box>

        {workshops.map((ws) => (
          <WorkshopCard
            key={ws.id}
            workshop={ws}
            budget={total_profit}
            tag_colors={tag_colors}
            attribute_colors={attribute_colors}
          />
        ))}

        <Box textAlign="center" mt={2}>
          <Button
            content={
              'Continue to Day ' + (current_day + 1)
            }
            icon="arrow-right"
            color="good"
            fontSize="13px"
            onClick={() => act('advance_from_shop')}
          />
        </Box>
      </Section>
    </Box>
  );
};

const WorkshopCard = (props, context) => {
  const { act } = useBackend(context);
  const {
    workshop,
    budget = 0,
    tag_colors = {},
    attribute_colors = {},
  } = props;

  const canAfford = budget >= workshop.cost;
  const isUnlocked = workshop.unlocked;

  return (
    <Box
      mb={1}
      p={1.5}
      style={{
        border: '2px solid ' + (
          isUnlocked
            ? 'rgba(0,200,0,0.4)'
            : workshop.color + '66'
        ),
        borderRadius: '4px',
        borderLeft: '4px solid ' + workshop.color,
        background: isUnlocked
          ? 'rgba(0,200,0,0.05)'
          : 'rgba(255,255,255,0.02)',
      }}>
      <Flex align="center" mb={1}>
        <Flex.Item grow={1}>
          <Box bold fontSize="13px" color={workshop.color}>
            {workshop.name}
            {isUnlocked && (
              <Box
                as="span"
                color="green"
                ml={1}
                fontSize="10px">
                PARTNERED
              </Box>
            )}
          </Box>
          <Box
            color="label"
            fontSize="11px"
            mt={0.5}
            italic>
            {workshop.desc}
          </Box>
        </Flex.Item>
        <Flex.Item>
          {isUnlocked ? (
            <Button
              icon="check"
              color="green"
              disabled
              content="Unlocked"
            />
          ) : (
            <Button
              icon="handshake"
              color={canAfford ? 'good' : 'grey'}
              disabled={!canAfford}
              content={workshop.cost + ' ahn'}
              onClick={() =>
                act('purchase_workshop', {
                  workshop_id: workshop.id,
                })}
            />
          )}
        </Flex.Item>
      </Flex>

      {/* Preview effects */}
      <Box fontSize="10px" color="grey" mb={0.5}>
        Unlocks {workshop.effects.length} effects:
      </Box>
      {workshop.effects.map((eff) => (
        <Box
          key={eff.id}
          ml={1}
          mb={0.5}
          fontSize="10px"
          style={{
            opacity: isUnlocked ? 1 : 0.7,
          }}>
          <Box as="span" bold mr={0.5}>
            {eff.name}
          </Box>
          <AttributeModifiers
            attributes={eff.attributes}
            attributeColors={attribute_colors}
          />
          {eff.tags
            && eff.tags.map((tag) => (
              <TagBadge
                key={tag}
                tag={tag}
                colors={tag_colors}
                small
              />
            ))}
          {eff.special && (
            <Box
              as="span"
              color="gold"
              ml={0.5}>
              ★
            </Box>
          )}
        </Box>
      ))}
    </Box>
  );
};

// =============================================
// Phase 5: Final Score
// =============================================

const FinalPhase = (props, context) => {
  const { data = {}, act } = useBackend(context);
  const {
    total_profit = 0,
    day_profits = [],
    fixer_designs = 0,
    ranking = {},
    unlocked_workshops = [],
  } = data;

  return (
    <Box>
      <Section>
        <Box textAlign="center" mt={2} mb={3}>
          <Box
            fontSize="20px"
            bold
            mb={1}
            style={{ fontFamily: 'Baskerville, Georgia, serif' }}>
            {ranking.title || 'Unknown'}
          </Box>
          <Box
            fontSize="36px"
            bold
            color={total_profit >= 0 ? '#FFD700' : '#CC4444'}
            mb={1}>
            {ranking.rank || '?'}
          </Box>
          <Box color="label" italic>
            {ranking.desc || ''}
          </Box>
        </Box>

        {/* Day-by-Day Summary */}
        <Section title="Day Summary">
          <Table>
            {day_profits.map((profit, i) => (
              <Table.Row key={i}>
                <Table.Cell bold>Day {i + 1}:</Table.Cell>
                <Table.Cell
                  textAlign="right"
                  color={profit >= 0 ? 'good' : 'bad'}>
                  {profit >= 0 ? '+' : ''}
                  {profit} ahn
                </Table.Cell>
              </Table.Row>
            ))}
            <Table.Row>
              <Table.Cell
                bold
                style={{
                  borderTop: '1px solid rgba(255,255,255,0.2)',
                }}>
                Total:
              </Table.Cell>
              <Table.Cell
                textAlign="right"
                bold
                color={total_profit >= 0 ? 'good' : 'bad'}
                style={{
                  borderTop: '1px solid rgba(255,255,255,0.2)',
                }}>
                {total_profit >= 0 ? '+' : ''}
                {total_profit} ahn
              </Table.Cell>
            </Table.Row>
          </Table>
        </Section>

        {/* Fixer Designs Counter */}
        <Box
          mt={2}
          p={1.5}
          textAlign="center"
          style={{
            border: '1px solid rgba(255,255,255,0.1)',
            borderRadius: '4px',
          }}>
          <Box color="label" mb={0.5}>
            Fixer Client Designs Completed:
          </Box>
          <Box bold fontSize="16px">
            {fixer_designs}
          </Box>
          {fixer_designs >= 3 && (
            <Box color="good" fontSize="11px" mt={0.5}>
              Penny will notice your Fixer expertise.
            </Box>
          )}
        </Box>

        {/* Workshop Partnerships */}
        {unlocked_workshops.length > 0 && (
          <Box
            mt={2}
            p={1.5}
            textAlign="center"
            style={{
              border: '1px solid rgba(255,255,255,0.1)',
              borderRadius: '4px',
            }}>
            <Box color="label" mb={0.5}>
              Workshop Partnerships:
            </Box>
            <Box bold fontSize="14px">
              {unlocked_workshops.length}
            </Box>
          </Box>
        )}

        {/* Ranking Thresholds */}
        <Box mt={2} color="grey" fontSize="10px" textAlign="center">
          S: 3000+ | A: 2000+ | B: 1200+ | C: 600+ | D: 0+ | F: Negative
        </Box>

        <Box textAlign="center" mt={2}>
          <Button
            content="Close Terminal"
            icon="times"
            onClick={() => act('close_game')}
          />
        </Box>
      </Section>
    </Box>
  );
};

// =============================================
// Shared Components
// =============================================

// Tag badge component
const TagBadge = (props) => {
  const { tag, colors = {}, small = false } = props;
  const bgColor = colors[tag] || '#666666';

  return (
    <Box
      as="span"
      mr={0.5}
      mb={0.5}
      px={small ? 0.5 : 1}
      py={0.25}
      style={{
        display: 'inline-block',
        background: bgColor,
        borderRadius: '3px',
        fontSize: small ? '9px' : '11px',
        color: '#FFFFFF',
        fontWeight: 'bold',
      }}>
      {tag}
    </Box>
  );
};
