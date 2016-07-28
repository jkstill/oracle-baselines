
Here's a method to find the periods of top activity in AWR and create a baseline for the top 10 periods.

The baseline can be made to expire after a set number of days so that you can just set them and forget them.

Use a reasonable value (30 days?) after which the baselines will just expire.

Be sure to allow enough time to ensure you will be done with them.

This code looks for the top 10 AAS (Average Active Sessions) periods and creates a baseline for each.

The same idea could be used to find top PGA usage, CPU, IO, etc.


