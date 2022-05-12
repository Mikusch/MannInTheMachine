void OnBombDeployStart(int other)
{
	Player(other).m_nDeployingBombState = TF_BOMB_DEPLOYING_DELAY;
	Player(other).m_nDeployingBombTimer.Start(tf_deploying_bomb_delay_time.FloatValue);
	
	// remember where we start deploying
	
}

void OnBombDeployEnd()
{
	// CTFPlayer::DoAnimationEvent
}
