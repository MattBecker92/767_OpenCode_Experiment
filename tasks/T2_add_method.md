# Task 2 — Add a Method

The `Scheduler` class has a method `get_by_tag(tag: str)` that returns jobs by tag.

Add a method called `get_by_priority(min_priority: int)` to the `Scheduler` class.

Requirements:
- It must return a list of Jobs where `job.priority >= min_priority`
- Sort the results from highest priority to lowest
- It must not modify `self.jobs`
- All existing tests must still pass after your change