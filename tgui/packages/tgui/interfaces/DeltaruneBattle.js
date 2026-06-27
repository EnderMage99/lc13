import { Component, createRef } from 'inferno';
import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { Box, Button, Stack } from '../components';
import { Window } from '../layouts';

const ARENA_W = 200;
const ARENA_H = 150;
const SOUL_SIZE = 16;
const SOUL_SPEED = 110;
const BULLET_SIZE = 18;

class BulletBox extends Component {
  constructor(props) {
    super(props);
    this.canvasRef = createRef();
    this.keys = { up: 0, down: 0, left: 0, right: 0 };
    this.soul = { x: ARENA_W / 2, y: ARENA_H / 2 };
    this.bullets = [];
    this.elapsed = 0;
    this.lastTime = 0;
    this.hits = 0;
    this.dead = false;
    this.onKeyDown = this.onKeyDown.bind(this);
    this.onKeyUp = this.onKeyUp.bind(this);
    this.tick = this.tick.bind(this);
  }

  componentDidMount() {
    const pat = this.props.pattern;
    if (pat && pat.bullets) {
      this.bullets = pat.bullets.map(b => ({
        spawnT: (b.t || 0) / 10,
        alive: false,
        x: b.x,
        y: b.y,
        vx: b.vx,
        vy: b.vy,
      }));
    }
    this.duration = (pat && pat.duration ? pat.duration : 60) / 10;
    window.addEventListener('keydown', this.onKeyDown);
    window.addEventListener('keyup', this.onKeyUp);
    this.lastTime = performance.now();
    this.raf = requestAnimationFrame(this.tick);
  }

  componentWillUnmount() {
    this.dead = true;
    window.removeEventListener('keydown', this.onKeyDown);
    window.removeEventListener('keyup', this.onKeyUp);
    if (this.raf) cancelAnimationFrame(this.raf);
  }

  onKeyDown(e) {
    if (e.key === 'ArrowUp' || e.key === 'w') this.keys.up = 1;
    if (e.key === 'ArrowDown' || e.key === 's') this.keys.down = 1;
    if (e.key === 'ArrowLeft' || e.key === 'a') this.keys.left = 1;
    if (e.key === 'ArrowRight' || e.key === 'd') this.keys.right = 1;
    if (this.keys.up || this.keys.down
        || this.keys.left || this.keys.right) {
      e.preventDefault();
    }
  }

  onKeyUp(e) {
    if (e.key === 'ArrowUp' || e.key === 'w') this.keys.up = 0;
    if (e.key === 'ArrowDown' || e.key === 's') this.keys.down = 0;
    if (e.key === 'ArrowLeft' || e.key === 'a') this.keys.left = 0;
    if (e.key === 'ArrowRight' || e.key === 'd') this.keys.right = 0;
  }

  tick(now) {
    if (this.dead) return;
    const dt = Math.min(0.05, (now - this.lastTime) / 1000);
    this.lastTime = now;
    this.elapsed += dt;
    const dx = (this.keys.right - this.keys.left) * SOUL_SPEED * dt;
    const dy = (this.keys.down - this.keys.up) * SOUL_SPEED * dt;
    this.soul.x = Math.max(SOUL_SIZE / 2,
      Math.min(ARENA_W - SOUL_SIZE / 2, this.soul.x + dx));
    this.soul.y = Math.max(SOUL_SIZE / 2,
      Math.min(ARENA_H - SOUL_SIZE / 2, this.soul.y + dy));
    for (const b of this.bullets) {
      if (!b.alive && this.elapsed >= b.spawnT) b.alive = true;
      if (!b.alive || b.removed) continue;
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      const colliding = Math.abs(b.x - this.soul.x) < (BULLET_SIZE / 2)
        && Math.abs(b.y - this.soul.y) < (BULLET_SIZE / 2);
      if (colliding) {
        b.removed = true;
        this.hits += 1;
      }
      if (b.x < -40 || b.x > ARENA_W + 40
          || b.y < -40 || b.y > ARENA_H + 40) {
        b.removed = true;
      }
    }
    this.draw();
    if (this.elapsed >= this.duration) {
      this.props.onDone(this.hits);
      this.dead = true;
      return;
    }
    this.raf = requestAnimationFrame(this.tick);
  }

  draw() {
    const c = this.canvasRef.current;
    if (!c) return;
    const ctx = c.getContext('2d');
    ctx.imageSmoothingEnabled = false;
    ctx.clearRect(0, 0, c.width, c.height);
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, c.width, c.height);
    ctx.strokeStyle = '#ffaf17';
    ctx.lineWidth = 4;
    ctx.strokeRect(2, 2, c.width - 4, c.height - 4);
    if (this.bulletImg && this.bulletImg.complete) {
      for (const b of this.bullets) {
        if (!b.alive || b.removed) continue;
        ctx.drawImage(this.bulletImg, b.x - BULLET_SIZE / 2,
          b.y - BULLET_SIZE / 2, BULLET_SIZE, BULLET_SIZE);
      }
    }
    if (this.soulImg && this.soulImg.complete) {
      ctx.drawImage(this.soulImg, this.soul.x - SOUL_SIZE / 2,
        this.soul.y - SOUL_SIZE / 2, SOUL_SIZE, SOUL_SIZE);
    }
  }

  render() {
    if (!this.soulImg) {
      this.soulImg = new Image();
      this.soulImg.src = resolveAsset('soul_red.png');
      this.soulImg.onload = () => this.draw();
    }
    if (!this.bulletImg) {
      this.bulletImg = new Image();
      this.bulletImg.src = resolveAsset('bullet_diamond.png');
      this.bulletImg.onload = () => this.draw();
    }
    return (
      <canvas
        ref={this.canvasRef}
        width={ARENA_W * 2}
        height={ARENA_H * 2}
        style={{
          'width': (ARENA_W * 2) + 'px',
          'height': (ARENA_H * 2) + 'px',
          'image-rendering': 'pixelated',
          'background': '#000',
        }} />
    );
  }
}

class FightTimingBar extends Component {
  constructor(props) {
    super(props);
    this.state = { pos: 0 };
    this.tick = this.tick.bind(this);
    this.onKey = this.onKey.bind(this);
    this.lastTime = 0;
  }

  componentDidMount() {
    window.addEventListener('keydown', this.onKey);
    this.lastTime = performance.now();
    this.raf = requestAnimationFrame(this.tick);
  }

  componentWillUnmount() {
    if (this.raf) cancelAnimationFrame(this.raf);
    window.removeEventListener('keydown', this.onKey);
  }

  tick(now) {
    const dt = (now - this.lastTime) / 1000;
    this.lastTime = now;
    let next = this.state.pos + dt * 0.9;
    if (next > 1) next -= 1;
    this.setState({ pos: next });
    this.raf = requestAnimationFrame(this.tick);
  }

  onKey(e) {
    if (e.key === ' ' || e.key === 'Enter' || e.key === 'z') {
      this.resolve();
    }
  }

  resolve() {
    if (this.done) return;
    this.done = true;
    const d = Math.abs(this.state.pos - 0.5);
    let q = 'miss';
    if (d < 0.05) q = 'great';
    else if (d < 0.18) q = 'good';
    this.props.onResolve(q);
  }

  render() {
    const w = 400;
    const cursorX = this.state.pos * w;
    return (
      <Box>
        <Box mb={1} color="#fff">
          * Press SPACE / ENTER when the cursor is centered.
        </Box>
        <Box
          width={w + 'px'}
          height="40px"
          backgroundColor="#000"
          style={{ 'border': '2px solid #fff', 'position': 'relative' }}>
          <Box style={{
            'position': 'absolute',
            'left': (w / 2 - 4) + 'px',
            'top': '0',
            'width': '8px',
            'height': '40px',
            'background': '#ffe14b',
          }} />
          <Box style={{
            'position': 'absolute',
            'left': (cursorX - 2) + 'px',
            'top': '0',
            'width': '4px',
            'height': '40px',
            'background': '#ff4040',
          }} />
        </Box>
        <Button mt={1} onClick={() => this.resolve()}>HIT</Button>
      </Box>
    );
  }
}

const ActionButton = (props, context) => {
  const { act } = useBackend(context);
  const { choice, sprite } = props;
  return (
    <Box
      mr={1}
      style={{ 'cursor': 'pointer', 'display': 'inline-block' }}
      onClick={() => act('menu_pick', { choice })}>
      <img
        src={resolveAsset(sprite)}
        style={{
          'width': '62px',
          'height': '64px',
          'image-rendering': 'pixelated',
        }} />
    </Box>
  );
};

const ActList = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Box>
      {data.act_options.map(name => (
        <Button
          key={name}
          mr={1}
          color="transparent"
          onClick={() => act('act_pick', { choice: name })}
          style={{ 'color': '#ffe14b', 'border': '2px solid #ffe14b' }}>
          * {name}
        </Button>
      ))}
    </Box>
  );
};

const ItemList = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Box>
      {data.item_options.map(it => (
        <Button
          key={it.name}
          mr={1}
          color="transparent"
          onClick={() => act('item_pick', { choice: it.name })}
          style={{ 'color': '#ffe14b', 'border': '2px solid #ffe14b' }}>
          * {it.name} — {it.desc}
        </Button>
      ))}
    </Box>
  );
};

const EnemyArea = (props, context) => {
  const { data } = useBackend(context);
  const showBubble = data.phase === 'enemy_intro'
    || data.phase === 'bullet_hell'
    || data.phase === 'menu';
  return (
    <Box style={{
      'position': 'absolute',
      'right': '60px',
      'top': '80px',
      'width': '180px',
      'text-align': 'center',
    }}>
      {showBubble && data.enemy_speech ? (
        <Box style={{
          'background': '#fff',
          'color': '#000',
          'border': '2px solid #000',
          'padding': '4px 6px',
          'margin-bottom': '8px',
          'font-family': 'monospace',
        }}>
          {data.enemy_speech}
        </Box>
      ) : null}
      <img
        src={resolveAsset(data.phase === 'end_win'
          ? 'rudinn_hurt.png'
          : data.phase === 'enemy_intro' ? 'rudinn_alt.png'
            : 'rudinn_idle.png')}
        style={{
          'width': '140px',
          'height': '160px',
          'image-rendering': 'pixelated',
        }} />
      <Box mt={1} style={{ 'color': '#fff' }}>
        {data.enemy_name} {data.enemy_hp}/{data.enemy_hp_max}
      </Box>
      <Box
        style={{
          'width': '140px',
          'height': '8px',
          'background': '#400',
          'margin': '4px auto',
          'border': '1px solid #fff',
        }}>
        <Box style={{
          'width': (data.enemy_hp / data.enemy_hp_max * 100) + '%',
          'height': '100%',
          'background': '#ff3030',
        }} />
      </Box>
    </Box>
  );
};

const PlayerArea = (props, context) => {
  const { data } = useBackend(context);
  return (
    <Box style={{
      'position': 'absolute',
      'left': '40px',
      'top': '100px',
      'width': '120px',
      'text-align': 'center',
    }}>
      {data.player_icon ? (
        <img
          src={'data:image/png;base64,' + data.player_icon}
          style={{
            'width': '96px',
            'height': '96px',
            'image-rendering': 'pixelated',
          }} />
      ) : (
        <Box style={{ 'color': '#fff' }}>(no icon)</Box>
      )}
    </Box>
  );
};

const BottomStrip = (props, context) => {
  const { act, data } = useBackend(context);
  const hpPct = (data.player_hp / data.player_hp_max) * 100;
  const renderMenu = () => {
    if (data.phase === 'menu') {
      return (
        <Stack>
          <ActionButton choice="fight"  sprite="btn_fight.png" />
          <ActionButton choice="act"    sprite="btn_act.png" />
          <ActionButton choice="item"   sprite="btn_item.png" />
          <ActionButton choice="spare"  sprite="btn_spare.png" />
          <ActionButton choice="defend" sprite="btn_defend.png" />
        </Stack>
      );
    }
    if (data.phase === 'fight_timing') {
      return (
        <FightTimingBar
          onResolve={q => act('fight_resolve', { quality: q })} />
      );
    }
    if (data.phase === 'act_list') return <ActList />;
    if (data.phase === 'item_list') return <ItemList />;
    return null;
  };
  return (
    <Box style={{
      'position': 'absolute',
      'left': '0',
      'right': '0',
      'bottom': '0',
      'background': '#000',
      'border-top': '4px solid #fff',
      'padding': '8px 16px',
      'color': '#fff',
      'font-family': 'monospace',
      'min-height': '120px',
    }}>
      <Stack align="center">
        <Stack.Item>
          <Box style={{ 'color': '#3ec1ff', 'font-weight': 'bold' }}>
            {data.player_name}
          </Box>
          <Box style={{
            'width': '180px',
            'height': '12px',
            'background': '#400',
            'border': '1px solid #fff',
            'margin-top': '2px',
          }}>
            <Box style={{
              'width': hpPct + '%',
              'height': '100%',
              'background': '#3ec1ff',
            }} />
          </Box>
          <Box mt={0.5}>HP {data.player_hp}/{data.player_hp_max}</Box>
          <Box>Mercy {data.mercy}%</Box>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          {renderMenu()}
          <Box mt={1} style={{ 'color': '#fff' }}>{data.dialog}</Box>
        </Stack.Item>
      </Stack>
    </Box>
  );
};

export const DeltaruneBattle = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window width={780} height={560}>
      <Window.Content style={{
        'background': '#000',
        'background-image':
          'url(' + resolveAsset('bg_battle.gif') + ')',
        'background-size': 'cover',
        'background-position': 'center',
        'image-rendering': 'pixelated',
        'overflow': 'hidden',
        'position': 'relative',
      }}>
        <PlayerArea />
        <EnemyArea />
        {data.phase === 'bullet_hell' && data.pattern ? (
          <Box style={{
            'position': 'absolute',
            'left': '50%',
            'top': '180px',
            'transform': 'translateX(-50%)',
          }}>
            <BulletBox
              pattern={data.pattern}
              onDone={h => act('bullet_hell_done', { hits: h })} />
          </Box>
        ) : null}
        <BottomStrip />
      </Window.Content>
    </Window>
  );
};
