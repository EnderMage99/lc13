import { useBackend, useSharedState } from '../backend';
import {
  AnimatedNumber,
  Button,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Tabs,
} from '../components';
import { Window } from '../layouts';

const damageTypes = [
  {
    label: 'Brute',
    type: 'bruteLoss',
  },
  {
    label: 'Burn',
    type: 'fireLoss',
  },
  {
    label: 'Toxin',
    type: 'toxLoss',
  },
  {
    label: 'Respiratory',
    type: 'oxyLoss',
  },
  {
    label: "Sanity",
    type: "sanityLoss",
  },
];

const ToolDisplay = props => {
  const { label, name, icon, note } = props;
  if (!name) {
    return null;
  }
  return (
    <div style={{
      'display': 'flex',
      'align-items': 'center',
      'padding': '2px 0',
    }}>
      <b style={{ 'margin-right': '4px' }}>
        {label}:
      </b>
      {!!icon && (
        <img
          src={
            'data:image/png;base64,' + icon
          }
          style={{
            'width': '32px',
            'height': '32px',
            'margin-right': '4px',
            '-ms-interpolation-mode':
              'nearest-neighbor',
            'image-rendering': 'pixelated',
          }} />
      )}
      <span>{name}</span>
      {!!note && (
        <i style={{ 'margin-left': '4px' }}>
          ({note})
        </i>
      )}
    </div>
  );
};

const GuideStep = props => {
  const { number, children } = props;
  return (
    <div style={{ 'padding': '2px 0' }}>
      <b>{number}.</b> {children}
    </div>
  );
};

export const OperatingComputer = (
  props,
  context
) => {
  const [tab, setTab] = useSharedState(
    context, 'tab', 1
  );
  return (
    <Window
      width={400}
      height={550}>
      <Window.Content scrollable>
        <Tabs>
          <Tabs.Tab
            selected={tab === 1}
            onClick={() => setTab(1)}>
            Patient State
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 2}
            onClick={() => setTab(2)}>
            Surgery Procedures
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 3}
            onClick={() => setTab(3)}>
            Surgery Guides
          </Tabs.Tab>
        </Tabs>
        {tab === 1 && (
          <PatientStateView />
        )}
        {tab === 2 && (
          <SurgeryProceduresView />
        )}
        {tab === 3 && (
          <SurgeryGuidesView />
        )}
      </Window.Content>
    </Window>
  );
};

const PatientStateView = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    table,
    procedures = [],
    patient = {},
  } = data;
  if (!table) {
    return (
      <NoticeBox>
        No Table Detected
      </NoticeBox>
    );
  }
  return (
    <>
      <Section title="Patient State">
        {patient && (
          <LabeledList>
            <LabeledList.Item
              label="State"
              color={patient.statstate}>
              {patient.stat}
            </LabeledList.Item>
            <LabeledList.Item
              label="Blood Type">
              {patient.blood_type}
            </LabeledList.Item>
            <LabeledList.Item label="Health">
              <ProgressBar
                value={patient.health}
                minValue={patient.minHealth}
                maxValue={patient.maxHealth}
                color={
                  patient.health >= 0
                    ? 'good'
                    : 'average'
                }>
                <AnimatedNumber
                  value={patient.health} />
              </ProgressBar>
            </LabeledList.Item>
            {damageTypes.map(type => (
              <LabeledList.Item
                key={type.type}
                label={type.label}>
                <ProgressBar
                  value={
                    patient[type.type]
                    / patient.maxHealth
                  }
                  color="bad">
                  <AnimatedNumber
                    value={
                      patient[type.type]
                    } />
                </ProgressBar>
              </LabeledList.Item>
            ))}
          </LabeledList>
        ) || (
          'No Patient Detected'
        )}
      </Section>
      {procedures.length === 0 && (
        <Section>
          No Active Procedures
        </Section>
      )}
      {procedures.map(procedure => (
        <Section
          key={procedure.name}
          title={procedure.name}>
          <LabeledList>
            <LabeledList.Item
              label="Next Step">
              {procedure.next_step}
              {procedure.chems_needed && (
                <>
                  <b>Required Chemicals:</b>
                  <br />
                  {procedure.chems_needed}
                </>
              )}
            </LabeledList.Item>
            {!!data.alternative_step && (
              <LabeledList.Item
                label="Alternative Step">
                {procedure.alternative_step}
                {procedure.alt_chems_needed
                  && (
                    <>
                      <b>
                        Required Chemicals:
                      </b>
                      <br />
                      {
                        procedure
                          .alt_chems_needed
                      }
                    </>
                  )}
              </LabeledList.Item>
            )}
          </LabeledList>
          {(procedure.basic_tool_name
            || procedure.adv_tool_name) && (
            <Section
              title="Recommended Tools"
              level={2}>
              <ToolDisplay
                label="Basic"
                name={
                  procedure.basic_tool_name
                }
                icon={
                  procedure.basic_tool_icon
                } />
              <ToolDisplay
                label="Advanced"
                name={
                  procedure.adv_tool_name
                }
                icon={
                  procedure.adv_tool_icon
                }
                note={
                  procedure.adv_tool_note
                } />
            </Section>
          )}
        </Section>
      ))}
    </>
  );
};

const SurgeryProceduresView = (
  props,
  context
) => {
  const { act, data } = useBackend(context);
  const {
    surgeries = [],
  } = data;
  return (
    <Section
      title="Advanced Surgery Procedures">
      <Button
        icon="download"
        content="Sync Research Database"
        onClick={() => act('sync')} />
      {surgeries.map(surgery => (
        <Section
          title={surgery.name}
          key={surgery.name}
          level={2}>
          {surgery.desc}
        </Section>
      ))}
    </Section>
  );
};

const SurgeryGuidesView = () => {
  return (
    <>
      <Section title="Healing Wounds">
        <b>Surgery to select: </b>
        {
          '\"Tend Wounds (Bruises)\" for'
          + ' brute, \"Tend Wounds (Burn)\"'
          + ' for burn, or'
          + ' \"Tend Wounds (Mixture)\"'
          + ' for both.'
        }
        <br /><br />
        Place the patient on an operating
        table or stasis bed. Use a
        {' '}<b>health analyzer</b> to
        check what type of damage they
        have. Place <b>surgical drapes
        </b> on the patient&apos;s chest
        to begin.
        <br /><br />
        <b>Steps:</b>
        <GuideStep number={1}>
          Careful incision
          {' '}(<b>scalpel</b>)
        </GuideStep>
        <GuideStep number={2}>
          Tend wounds
          {' '}(<b>hemostat</b>)
          {' '}<i>- repeatable until
          {' '}healed</i>
        </GuideStep>
        <GuideStep number={3}>
          Mend incision
          {' '}(<b>cautery</b>)
        </GuideStep>
      </Section>

      <Section title="Replacing a Missing Limb">
        <b>Surgery to select: </b>
        {
          '\"Prosthetic replacement\"'
        }
        <br /><br />
        For limbs that have been lost or
        amputated. Target the missing
        limb&apos;s body zone with your
        target selector, then place
        {' '}<b>surgical drapes</b> on
        the area.
        <br /><br />
        <b>Steps:</b>
        <GuideStep number={1}>
          Make incision
          {' '}(<b>scalpel</b>)
        </GuideStep>
        <GuideStep number={2}>
          Clamp bleeders
          {' '}(<b>hemostat</b>)
        </GuideStep>
        <GuideStep number={3}>
          Retract skin
          {' '}(<b>retractor</b>)
        </GuideStep>
        <GuideStep number={4}>
          Attach new limb
          {' '}(<b>bodypart or
          {' '}robotic part</b>)
        </GuideStep>
        <br />
        <i>
          Organic limbs from the same
          species work best. Robotic
          parts are always accepted.
        </i>
      </Section>

      <Section
        title="Augmenting a Limb">
        <b>Surgery to select: </b>
        {
          '\"Augmentation\"'
        }
        <br /><br />
        Replaces an existing organic limb
        with a robotic augment. No
        amputation needed. Can target
        arms, legs, chest, or head.
        Place <b>surgical drapes</b> on
        the target area.
        <br /><br />
        <b>Steps:</b>
        <GuideStep number={1}>
          Make incision
          {' '}(<b>scalpel</b>)
        </GuideStep>
        <GuideStep number={2}>
          Clamp bleeders
          {' '}(<b>hemostat</b>)
        </GuideStep>
        <GuideStep number={3}>
          Retract skin
          {' '}(<b>retractor</b>)
        </GuideStep>
        <GuideStep number={4}>
          Replace limb
          {' '}(<b>robotic
          {' '}bodypart</b>)
        </GuideStep>
        <br />
        <i>
          The original organic limb is
          replaced directly with the
          augment.
        </i>
      </Section>

      <Section
        title="Installing a Body Mod">
        <b>Surgery to select: </b>
        {
          '\"Organ manipulation\"'
          + ' (target the chest)'
        }
        <br /><br />
        Skill modifications created by the
        Body Modification Fabricator come
        in two types:
        <br /><br />
        <b>Implantable (organ):</b>
        {' '}Requires surgery. Place
        {' '}<b>surgical drapes</b> on
        the patient&apos;s chest and
        select Organ manipulation.
        <br /><br />
        <b>Steps:</b>
        <GuideStep number={1}>
          Make incision
          {' '}(<b>scalpel</b>)
        </GuideStep>
        <GuideStep number={2}>
          Retract skin
          {' '}(<b>retractor</b>)
        </GuideStep>
        <GuideStep number={3}>
          Saw bone
          {' '}(<b>circular saw</b>)
        </GuideStep>
        <GuideStep number={4}>
          Clamp bleeders
          {' '}(<b>hemostat</b>)
        </GuideStep>
        <GuideStep number={5}>
          Make incision
          {' '}(<b>scalpel</b>)
        </GuideStep>
        <GuideStep number={6}>
          Insert the skill modification
          {' '}(<b>skill mod organ</b>)
          {' '}<i>- use the organ on
          {' '}the patient</i>
        </GuideStep>
        <GuideStep number={7}>
          Mend incision
          {' '}(<b>cautery</b>)
        </GuideStep>
        <br />
        <i>
          To remove an installed mod,
          repeat the same surgery and use
          a <b>hemostat</b> at step 6
          to extract it instead.
        </i>
        <br /><br />
        <b>Injectable:</b>
        {' '}No surgery needed. Simply
        use the injectable modification
        on the target patient directly.
        Takes 3 seconds.
        <br /><br />
        <i>
          Both types require the
          patient to meet minimum stat
          requirements based on the
          mod&apos;s rank.
        </i>
      </Section>

      <Section
        title="Preparing a Body for Revival">
        Before reviving a dead patient
        by any method, you must prepare
        the body first.
        <br /><br />
        <GuideStep number={1}>
          Get the patient on a
          {' '}<b>stasis bed</b> to halt
          organ decay.
        </GuideStep>
        <GuideStep number={2}>
          Use a <b>health analyzer</b>
          {' '}to assess their damage
          and check for brain trauma
          or failed organs.
        </GuideStep>
        <GuideStep number={3}>
          Heal their brute and burn
          damage using
          {' '}<b>Tend Wounds</b>
          {' '}surgery, but do NOT
          heal them fully.
        </GuideStep>
        <br />
        <NoticeBox danger>
          Do NOT fully heal the patient
          before reviving! Dead patients
          accumulate oxygen damage over
          time. If you heal all
          brute/burn to 0, the oxygen
          damage alone may exceed the
          death threshold and they will
          die again immediately. Heal
          to around 170 total damage,
          then revive.
        </NoticeBox>
        <i>
          If cerebral trauma is detected,
          perform
          {' '}<b>
            &quot;Brain surgery&quot;
          </b>
          {' '}(target head) before
          revival. If organs are
          non-functional, use
          {' '}<b>
            &quot;Organ manipulation&quot;
          </b>
          {' '}to repair or remove them.
        </i>
      </Section>

      <Section
        title="Revival: Defibrillator">
        The quickest way to revive a
        patient. No surgery needed, but
        requires a charged defibrillator.
        <br /><br />
        <b>How to use:</b>
        <GuideStep number={1}>
          Equip the defibrillator on
          your <b>back slot</b>
        </GuideStep>
        <GuideStep number={2}>
          Click the defibrillator or
          press its <b>action button
          </b> to pull out the paddles
          {' '}(needs a free hand)
        </GuideStep>
        <GuideStep number={3}>
          Use the <b>paddles</b> on
          the dead patient to shock
          them
        </GuideStep>
        <i>
          The paddles have a short
          cooldown between uses.
          Click the defib again to
          put the paddles away.
        </i>
        <br /><br />
        <b>Pros:</b>
        <div style={{
          'padding-left': '8px',
        }}>
          - Fast and simple, no surgery
          {' '}skill needed
          <br />
          - Can be done anywhere, no
          {' '}operating table required
          <br />
          - Patient does not need to be
          {' '}on a table or stasis bed
        </div>
        <b>Cons:</b>
        <div style={{
          'padding-left': '8px',
        }}>
          - Requires a charged
          {' '}defibrillator
          <br />
          - Cannot revive through thick
          {' '}clothing covering the chest
          {' '}(unless combat defib)
          <br />
          - Will fail if the body has
          {' '}too much damage, missing
          {' '}heart, or missing brain
        </div>
      </Section>

      <Section
        title="Revival: Surgery">
        <b>Surgery to select: </b>
        {
          '\"Revival\" (target the head)'
        }
        <br /><br />
        A surgical procedure to revive
        the dead. Requires an operating
        table or stasis bed and surgical
        tools.
        <br /><br />
        <b>Steps:</b>
        <GuideStep number={1}>
          Make incision
          {' '}(<b>scalpel</b>)
        </GuideStep>
        <GuideStep number={2}>
          Retract skin
          {' '}(<b>retractor</b>)
        </GuideStep>
        <GuideStep number={3}>
          Saw bone
          {' '}(<b>circular saw</b>)
        </GuideStep>
        <GuideStep number={4}>
          Clamp bleeders
          {' '}(<b>hemostat</b>)
        </GuideStep>
        <GuideStep number={5}>
          Make incision
          {' '}(<b>scalpel</b>)
        </GuideStep>
        <GuideStep number={6}>
          Shock body
          {' '}(<b>defibrillator
          {' '}paddles</b>)
          {' '}<i>- repeatable</i>
        </GuideStep>
        <GuideStep number={7}>
          Mend incision
          {' '}(<b>cautery</b>)
        </GuideStep>
        <br />
        <b>Pros:</b>
        <div style={{
          'padding-left': '8px',
        }}>
          - Works even when the body
          {' '}has more damage than a
          {' '}regular defib can handle
          <br />
          - Ignores thick clothing
          <br />
          - The surgery itself heals
          {' '}some brute damage through
          {' '}the saw and close steps
        </div>
        <b>Cons:</b>
        <div style={{
          'padding-left': '8px',
        }}>
          - Requires an operating table
          {' '}or stasis bed
          <br />
          - Takes longer and needs
          {' '}multiple surgical tools
          <br />
          - Still requires defibrillator
          {' '}paddles for the shock step
        </div>
      </Section>

      <Section title="Using the Sleeper">
        The sleeper can heal patients
        who are alive or freshly revived.
        Place the patient inside and use
        the console to inject chemicals.
        <b>
          {' '}Hover over each button for
          a description.
        </b>
        <br /><br />
        <b>Available Chemicals:</b>
        <div style={{
          'padding-left': '8px',
        }}>
          <div style={{
            'padding': '2px 0',
          }}>
            <b>Epinephrine</b> - Slowly
            heals damage when in critical
            condition and regulates oxygen
            loss. Minor stun resistance.
            Can be injected even at low
            health.
          </div>
          <div style={{
            'padding': '2px 0',
          }}>
            <b>L-Corp Healing Gel</b>
            {' '}- Restores 3 HP per
            cycle. Overdoses at 30 units.
          </div>
          <div style={{
            'padding': '2px 0',
          }}>
            <b>L-Corp SP Plus</b>
            {' '}- Restores 3 sanity per
            cycle. Overdoses at 30 units.
          </div>
          <div style={{
            'padding': '2px 0',
          }}>
            <b>L-Corp BurnSalve</b>
            {' '}- Heals burn damage
            slowly, but slightly damages
            eyes as a side effect.
          </div>
          <div style={{
            'padding': '2px 0',
          }}>
            <b>Universal Antitoxin</b>
            {' '}- Removes toxin damage.
            Overdoses at 30 units.
          </div>
          <div style={{
            'padding': '2px 0',
          }}>
            <b>K-Corp Purge-All</b>
            {' '}- Purges ALL other
            chemicals from the body.
            Use if harmful chemicals
            are present.
          </div>
        </div>
        <br />
        <b>After Revival:</b>
        <div style={{
          'padding-left': '8px',
        }}>
          A freshly revived patient will
          have high oxygen damage. Place
          them in the sleeper and inject
          {' '}<b>Epinephrine</b> first
          to stabilize them, then use
          {' '}<b>Healing Gel</b> and
          {' '}<b>SP Plus</b> to restore
          health and sanity. Watch the
          reagent levels to avoid
          overdose (30 units max).
        </div>
        <br />
        <b>For Living Patients:</b>
        <div style={{
          'padding-left': '8px',
        }}>
          Use the appropriate chemical
          for their damage type. Check
          the damage bars on the sleeper
          console to see what they need.
          Use <b>Purge-All</b> if they
          have been poisoned or have
          unwanted chemicals.
        </div>
      </Section>
    </>
  );
};
