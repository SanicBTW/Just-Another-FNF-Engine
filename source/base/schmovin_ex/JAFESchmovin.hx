package base.schmovin_ex;

import schmovin.SchmovinStandalone;

class JAFESchmovin extends SchmovinStandalone
{
	override private function initializeAdapter()
	{
		SchmovinAdapter.setInstance(new JAFESchmovinAdapter());
	}
}
