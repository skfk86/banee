import React from 'react';
import {Audio, AbsoluteFill, Img, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig, Easing} from 'remotion';
import {continueRender, delayRender} from 'remotion';
const fontFamily = 'Cairo';
const fontHandle = delayRender('font');
new FontFace(fontFamily, `url(${staticFile('cairo.woff2')}) format('woff2')`, {weight: '200 1000'}).load()
  .then((ff) => { document.fonts.add(ff); continueRender(fontHandle); });

const C = {primary: '#2C64DD', accent: '#0BBF8A', ink: '#0E1525', bg: '#060A16', soft: '#EBF1FE'};
export const DURATION = 1020;
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

const useLayout = () => {
  const {width, height} = useVideoConfig();
  const portrait = height > width;
  return {portrait, u: Math.min(width, height) / 1080};
};

const fade = (f: number, a: number, b: number, len: number) =>
  interpolate(f, [a, a + 12, b - len, b], [0, 1, 1, 0], clamp);

const Background: React.FC = () => {
  const f = useCurrentFrame();
  const t = f / 30;
  return (
    <AbsoluteFill style={{background: C.bg, overflow: 'hidden'}}>
      <div style={{position: 'absolute', width: '90%', height: '90%', left: `${-20 + Math.sin(t * 0.4) * 8}%`, top: `${-30 + Math.cos(t * 0.3) * 6}%`,
        background: `radial-gradient(circle, ${C.primary}88 0%, transparent 60%)`, filter: 'blur(60px)'}}/>
      <div style={{position: 'absolute', width: '80%', height: '80%', right: `${-20 + Math.cos(t * 0.5) * 8}%`, bottom: `${-30 + Math.sin(t * 0.35) * 6}%`,
        background: `radial-gradient(circle, ${C.accent}66 0%, transparent 60%)`, filter: 'blur(60px)'}}/>
      <AbsoluteFill style={{backgroundImage: 'linear-gradient(rgba(255,255,255,.04) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.04) 1px, transparent 1px)',
        backgroundSize: '80px 80px', transform: `translateY(${(f * 0.6) % 80}px)`, maskImage: 'radial-gradient(circle at center, black 30%, transparent 75%)'}}/>
    </AbsoluteFill>
  );
};

const Words: React.FC<{text: string; delay?: number; size: number; color?: string; weight?: number}> = ({text, delay = 0, size, color = '#fff', weight = 900}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <div style={{display: 'flex', flexWrap: 'wrap', justifyContent: 'center', gap: `0 ${size * 0.28}px`, fontSize: size, fontWeight: weight, color, lineHeight: 1.35}}>
      {text.split(' ').map((w, i) => {
        const s = spring({frame: f - delay - i * 4, fps, config: {damping: 14, mass: 0.6}});
        return <span key={i} style={{opacity: s, transform: `translateY(${(1 - s) * size * 0.6}px)`, filter: `blur(${(1 - s) * 8}px)`, display: 'inline-block'}}>{w}</span>;
      })}
    </div>
  );
};

const Gradient: React.FC<{children: React.ReactNode}> = ({children}) => (
  <span style={{background: `linear-gradient(90deg, ${C.accent}, #6FA2FF)`, WebkitBackgroundClip: 'text', color: 'transparent'}}>{children}</span>
);

const Phone: React.FC<{children: React.ReactNode; scale?: number; style?: React.CSSProperties}> = ({children, scale = 1, style}) => {
  const {u} = useLayout();
  const w = 400 * u * scale, h = 820 * u * scale;
  return (
    <div style={{width: w, height: h, borderRadius: 60 * u * scale, background: '#0b0f1c', padding: 12 * u * scale,
      boxShadow: `0 0 0 ${2 * u}px #2a3350, 0 40px 120px ${C.primary}66`, ...style}}>
      <div style={{width: '100%', height: '100%', borderRadius: 48 * u * scale, background: '#F6F7FB', overflow: 'hidden', position: 'relative', direction: 'rtl'}}>
        {children}
      </div>
    </div>
  );
};

// 1. Hook
const Hook: React.FC = () => {
  const f = useCurrentFrame();
  const {u} = useLayout();
  return (
    <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center', opacity: fade(f, 0, 100, 12), padding: 60 * u}}>
      <Words text="عندك فكرة تطبيق؟" size={130 * u}/>
      <div style={{height: 20 * u}}/>
      <Sequence from={40} layout="none"><Words text="ولا تعرف البرمجة؟" size={80 * u} color="#9FB3D9" weight={700}/></Sequence>
    </AbsoluteFill>
  );
};

// 2. Describe
const PROMPT = 'أبغى تطبيق حجوزات لصالون تجميل، فيه خدمات وأسعار ومواعيد وإشعارات';
const Describe: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const {portrait, u} = useLayout();
  const words = PROMPT.split(' ');
  const shown = words.slice(0, Math.floor(interpolate(f, [25, 110], [0, words.length], clamp))).join(' ');
  const enter = spring({frame: f, fps, config: {damping: 16}});
  const sent = f > 120;
  return (
    <AbsoluteFill style={{flexDirection: portrait ? 'column' : 'row-reverse', justifyContent: 'center', alignItems: 'center', gap: 90 * u, opacity: fade(f, 0, 160, 12)}}>
      <div style={{textAlign: 'center', maxWidth: portrait ? '90%' : '42%'}}>
        <Words text="صِفها بكلماتك" size={110 * u}/>
        <Sequence from={15} layout="none"><Words text="بالعربي، كما تحكيها لصديق" size={52 * u} color="#9FB3D9" weight={700}/></Sequence>
      </div>
      <Phone scale={portrait ? 1.15 : 1} style={{transform: `translateY(${(1 - enter) * 300}px) rotate(${(1 - enter) * -8}deg)`}}>
        <div style={{padding: 28 * u, fontSize: 24 * u, color: C.ink}}>
          <div style={{fontWeight: 900, fontSize: 34 * u, color: C.primary, marginTop: 30 * u}}>بانِي</div>
          <div style={{color: '#6B7690', marginBottom: 30 * u}}>ماذا تريد أن تبني اليوم؟</div>
          {sent && <div style={{background: C.primary, color: '#fff', borderRadius: 22 * u, padding: 20 * u, marginBottom: 16 * u, lineHeight: 1.6,
            transform: `scale(${spring({frame: f - 120, fps, config: {damping: 12}})})`, transformOrigin: 'right top'}}>{PROMPT}</div>}
          {f > 135 && <div style={{background: '#fff', borderRadius: 22 * u, padding: 20 * u, border: '1px solid #E3E7EF', opacity: interpolate(f, [135, 145], [0, 1], clamp)}}>
            جاري البناء{'.'.repeat(1 + Math.floor(f / 6) % 3)}</div>}
        </div>
        <div style={{position: 'absolute', bottom: 24 * u, left: 20 * u, right: 20 * u, background: '#fff', border: `2px solid ${sent ? '#E3E7EF' : C.primary}`,
          borderRadius: 30 * u, padding: `${18 * u}px ${22 * u}px`, fontSize: 22 * u, minHeight: 60 * u, color: C.ink, lineHeight: 1.5}}>
          {sent ? <span style={{color: '#9aa3b8'}}>اكتب طلبك…</span> : <>{shown}<span style={{opacity: Math.floor(f / 8) % 2, color: C.primary}}>|</span></>}
        </div>
      </Phone>
    </AbsoluteFill>
  );
};

// 3. Agents
const STEPS = [['🧭', 'يخطط الشاشات'], ['🎨', 'يصمم هوية تناسب مجالك'], ['✍️', 'يكتب المحتوى كاملاً'], ['🗄️', 'يجهّز قاعدة البيانات'], ['🧪', 'يجرّب ويصلح الأخطاء بنفسه']];
const Agents: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const {u} = useLayout();
  return (
    <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center', opacity: fade(f, 0, 170, 12), padding: 60 * u}}>
      <Words text="فريق من وكلاء الذكاء الاصطناعي" size={84 * u}/>
      <Sequence from={10} layout="none"><Words text="يعمل لأجلك" size={84 * u} color={C.accent}/></Sequence>
      <div style={{marginTop: 50 * u, display: 'flex', flexDirection: 'column', gap: 18 * u, width: 760 * u}}>
        {STEPS.map(([ic, t], i) => {
          const st = 30 + i * 22;
          const s = spring({frame: f - st, fps, config: {damping: 15}});
          const done = f > st + 18;
          return (
            <div key={i} style={{display: 'flex', alignItems: 'center', gap: 22 * u, padding: `${18 * u}px ${28 * u}px`, borderRadius: 24 * u,
              background: 'rgba(255,255,255,.06)', border: `1px solid ${done ? C.accent + '99' : 'rgba(255,255,255,.12)'}`, backdropFilter: 'blur(10px)',
              opacity: s, transform: `translateX(${(1 - s) * -120}px)`, color: '#fff', fontSize: 40 * u, fontWeight: 700}}>
              <span style={{fontSize: 44 * u}}>{ic}</span>
              <span style={{flex: 1}}>{t}</span>
              <span style={{width: 50 * u, height: 50 * u, borderRadius: '50%', display: 'grid', placeItems: 'center', fontSize: 30 * u,
                background: done ? C.accent : 'transparent', border: done ? 'none' : `3px solid ${C.primary}`,
                transform: `rotate(${done ? 0 : f * 12}deg)`, borderTopColor: done ? undefined : 'transparent'}}>{done ? '✓' : ''}</span>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

// 4. Reveal
const AppScreen: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const {u} = useLayout();
  const items = [['قص وتصفيف', '٨٠ ر.س'], ['صبغة شعر', '٢٢٠ ر.س'], ['مكياج سهرة', '٣٥٠ ر.س'], ['عناية بالبشرة', '١٨٠ ر.س']];
  return (
    <div style={{fontSize: 22 * u, color: C.ink}}>
      <div style={{background: 'linear-gradient(135deg, #C2185B, #8E24AA)', color: '#fff', padding: `${60 * u}px ${28 * u}px ${36 * u}px`}}>
        <div style={{fontSize: 20 * u, opacity: .85}}>أهلاً بك في</div>
        <div style={{fontSize: 40 * u, fontWeight: 900}}>صالون لمسة</div>
        <div style={{marginTop: 16 * u, background: 'rgba(255,255,255,.2)', borderRadius: 18 * u, padding: 14 * u}}>📅 موعدك القادم: الخميس ٤:٠٠ م</div>
      </div>
      <div style={{padding: 22 * u, display: 'flex', flexDirection: 'column', gap: 14 * u}}>
        <div style={{fontWeight: 900, fontSize: 26 * u}}>خدماتنا</div>
        {items.map(([n, p], i) => {
          const s = spring({frame: f - 20 - i * 6, fps, config: {damping: 14}});
          return <div key={i} style={{background: '#fff', borderRadius: 18 * u, padding: 18 * u, display: 'flex', justifyContent: 'space-between',
            boxShadow: '0 4px 14px rgba(0,0,0,.06)', opacity: s, transform: `translateY(${(1 - s) * 40}px)`}}>
            <b>{n}</b><span style={{color: '#C2185B', fontWeight: 700}}>{p}</span></div>;
        })}
        <div style={{marginTop: 8 * u, background: '#C2185B', color: '#fff', textAlign: 'center', borderRadius: 18 * u, padding: 18 * u, fontWeight: 900}}>احجزي موعدك</div>
      </div>
    </div>
  );
};
const Reveal: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const {portrait, u} = useLayout();
  const s = spring({frame: f, fps, config: {damping: 13, mass: 0.9}});
  const flash = interpolate(f, [0, 4, 20], [0, 0.7, 0], clamp);
  return (
    <AbsoluteFill style={{flexDirection: portrait ? 'column' : 'row-reverse', justifyContent: 'center', alignItems: 'center', gap: 90 * u, opacity: fade(f, 0, 160, 12)}}>
      <div style={{textAlign: 'center', maxWidth: portrait ? '90%' : '42%'}}>
        <Words text="ودقائق…" size={70 * u} color="#9FB3D9" weight={700}/>
        <Sequence from={12} layout="none"><Words text="تطبيقك جاهز!" size={130 * u}/></Sequence>
        <Sequence from={30} layout="none"><Words text="حقيقي، يعمل، وملكك بالكامل" size={50 * u} color={C.accent} weight={700}/></Sequence>
      </div>
      <Phone scale={portrait ? 1.15 : 1} style={{transform: `scale(${0.6 + s * 0.4}) rotateY(${(1 - s) * 40}deg)`, opacity: s}}>
        <AppScreen/>
      </Phone>
      <AbsoluteFill style={{background: '#fff', opacity: flash, pointerEvents: 'none'}}/>
    </AbsoluteFill>
  );
};

// 5. Features
const FEATS = [['🔐', 'حسابات وحجوزات ودردشة'], ['🛠️', 'لوحة إدارة وإشعارات'], ['🤖', 'ذكاء اصطناعي داخل تطبيقك'], ['🌦️', 'بيانات حية: طقس، عملات، صلاة'], ['💬', 'عدّل بالمحادثة ومعاينة فورية'], ['📦', 'جاهز للنشر على Google Play']];
const Features: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const {portrait, u} = useLayout();
  return (
    <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center', opacity: fade(f, 0, 160, 12), padding: 60 * u}}>
      <Words text="كل ما يحتاجه تطبيق احترافي" size={86 * u}/>
      <div style={{marginTop: 50 * u, display: 'grid', gridTemplateColumns: portrait ? '1fr 1fr' : '1fr 1fr 1fr', gap: 24 * u, width: portrait ? '100%' : 1500 * u}}>
        {FEATS.map(([ic, t], i) => {
          const s = spring({frame: f - 15 - i * 7, fps, config: {damping: 13}});
          return <div key={i} style={{background: 'linear-gradient(160deg, rgba(255,255,255,.10), rgba(255,255,255,.03))', border: '1px solid rgba(255,255,255,.14)',
            borderRadius: 30 * u, padding: 34 * u, color: '#fff', textAlign: 'center', opacity: s, transform: `scale(${0.7 + s * 0.3})`}}>
            <div style={{fontSize: 70 * u}}>{ic}</div>
            <div style={{fontSize: 36 * u, fontWeight: 700, marginTop: 10 * u, lineHeight: 1.4}}>{t}</div>
          </div>;
        })}
      </div>
    </AbsoluteFill>
  );
};

// 5b. Real app screens
const RealApp: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const {portrait, u} = useLayout();
  const sc = portrait ? 1.05 : 0.72;
  return (
    <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center', opacity: fade(f, 0, 125, 12), padding: 40 * u}}>
      <Words text="جرّبه بنفسك على هاتفك" size={84 * u}/>
      <div style={{display: 'flex', flexDirection: 'row-reverse', marginTop: 40 * u, gap: portrait ? 0 : 40 * u}}>
        {[1, 2, 3].map((n, i) => {
          const s = spring({frame: f - 10 - i * 8, fps, config: {damping: 14}});
          const rot = portrait ? (i - 1) * 8 : (i - 1) * 4;
          return <Phone key={n} scale={sc} style={{opacity: s, margin: portrait ? `0 ${-50 * u}px` : 0, zIndex: i === 1 ? 2 : 1,
            transform: `translateY(${(1 - s) * 400 + (i === 1 ? -30 : 20) * u}px) rotate(${rot * s}deg)`}}>
            <Img src={staticFile(`real${n}.png`)} style={{width: '100%', height: '100%', objectFit: 'cover'}}/>
          </Phone>;
        })}
      </div>
    </AbsoluteFill>
  );
};

// 6. Outro
const Outro: React.FC = () => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const {u} = useLayout();
  const s = spring({frame: f, fps, config: {damping: 10, mass: 0.8}});
  const glow = 0.5 + Math.sin(f / 8) * 0.25;
  const out = interpolate(f, [150, 180], [1, 0], clamp);
  return (
    <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center', opacity: out, padding: 60 * u}}>
      <div style={{width: 240 * u, height: 240 * u, borderRadius: 60 * u, overflow: 'hidden', transform: `scale(${s}) rotate(${(1 - s) * -30}deg)`,
        boxShadow: `0 0 ${120 * u}px ${C.primary}${Math.round(glow * 255).toString(16).padStart(2, '0')}`}}>
        <Img src={staticFile('icon.png')} style={{width: '100%', height: '100%'}}/>
      </div>
      <div style={{height: 30 * u}}/>
      <Sequence from={10} layout="none"><Words text="بانِي" size={160 * u}/></Sequence>
      <Sequence from={25} layout="none">
        <div style={{fontSize: 60 * u, fontWeight: 900, color: '#fff', textAlign: 'center', opacity: interpolate(f, [25, 40], [0, 1], clamp)}}>
          صِف فكرتك… <Gradient>ونبنيه لك</Gradient>
        </div>
      </Sequence>
      <div style={{marginTop: 50 * u, display: 'flex', alignItems: 'center', gap: 18 * u, background: '#000', border: '2px solid #555', borderRadius: 22 * u,
        padding: `${16 * u}px ${36 * u}px`, color: '#fff', opacity: interpolate(f, [45, 60], [0, 1], clamp),
        transform: `translateY(${interpolate(f, [45, 60], [40, 0], {...clamp, easing: Easing.out(Easing.cubic)})}px)`}}>
        <svg width={56 * u} height={56 * u} viewBox="0 0 24 24"><path fill="#34A853" d="M3.6 1.8 13.8 12 3.6 22.2c-.4-.2-.6-.7-.6-1.2V3c0-.5.2-1 .6-1.2z"/><path fill="#FBBC04" d="m17.3 8.5-3.5 3.5 3.5 3.5 4-2.3c.9-.5.9-1.9 0-2.4z"/><path fill="#4285F4" d="M3.6 1.8c.3-.2.8-.2 1.2 0l12.5 6.7-3.5 3.5z"/><path fill="#EA4335" d="M13.8 12l3.5 3.5-12.5 6.7c-.4.2-.9.2-1.2 0z"/></svg>
        <div style={{lineHeight: 1.2}}>
          <div style={{fontSize: 22 * u, opacity: .8}}>حمّله الآن من</div>
          <div style={{fontSize: 40 * u, fontWeight: 900, direction: 'ltr'}}>Google Play</div>
        </div>
      </div>
      <div style={{marginTop: 26 * u, color: '#9FB3D9', fontSize: 32 * u, fontWeight: 700, opacity: interpolate(f, [65, 80], [0, 1], clamp)}}>ابدأ مجاناً اليوم</div>
    </AbsoluteFill>
  );
};

export const BaneePromo: React.FC = () => (
  <AbsoluteFill style={{direction: 'rtl', fontFamily: `${fontFamily}, 'DejaVu Sans', sans-serif`}}>
    <Background/>
    <Sequence durationInFrames={100}><Hook/></Sequence>
    <Sequence from={95} durationInFrames={160}><Describe/></Sequence>
    <Sequence from={250} durationInFrames={170}><Agents/></Sequence>
    <Sequence from={415} durationInFrames={160}><Reveal/></Sequence>
    <Sequence from={570} durationInFrames={160}><Features/></Sequence>
    <Sequence from={720} durationInFrames={125}><RealApp/></Sequence>
    <Sequence from={840} durationInFrames={180}><Outro/></Sequence>
    <Audio src={staticFile('music.wav')} volume={(f) => interpolate(f, [0, 15, DURATION - 40, DURATION], [0, 1, 1, 0], clamp)}/>
  </AbsoluteFill>
);
