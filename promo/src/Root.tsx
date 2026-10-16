import {Composition} from 'remotion';
import {BaneePromo, DURATION} from './BaneePromo';
export const RemotionRoot = () => (<>
  <Composition id="BaneePromo" component={BaneePromo} durationInFrames={DURATION} fps={30} width={1920} height={1080}/>
  <Composition id="BaneeReel" component={BaneePromo} durationInFrames={DURATION} fps={30} width={1080} height={1920}/>
</>);
