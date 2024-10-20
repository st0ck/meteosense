# Core requirements

- Must be done in Ruby on Rails
- Accept an address as input
- Retrieve forecast data for the given address. This should include, at minimum, the current temperature (Bonus points - Retrieve high/low and/or extended forecast)
- Display the requested forecast details to the user
- Cache the forecast details for 30 minutes for all subsequent requests by zip codes. Display indicator if result is pulled from cache.
- This project is open to interpretation
- Functionality is a priority over form
- If you get stuck, complete as much as you can

# Assumptions

Assuming that the following topics are out of scope:
- observability
- monitoring
- alerting
- logs
- deploy
- integration/e2e tests
- authorization
- load testing
- rate limiting
- clusterization for the cache
- validating data coming from integrations
- API parametrization (languages/units/forecast days number)

Using zip codes in cache is ineffective as the grids in different coutrie will be unequal.
For example, in UK ZIP codes cover very small area (as low as 20-30m) which will lead to big number
of cache misses despite the fact It will consume more memory that in most other countries. Much more
efficient would be using a geospatial zoning. In this example H3 algorithm is used.
