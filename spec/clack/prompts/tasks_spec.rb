RSpec.describe Clack::Prompts::Tasks do
  let(:output) { StringIO.new }

  def create_tasks(task_list)
    described_class.new(tasks: task_list, output: output)
  end

  describe "#run" do
    it "executes all tasks" do
      executed = []
      tasks = create_tasks([
        {title: "Task 1", task: -> { executed << 1 }},
        {title: "Task 2", task: -> { executed << 2 }}
      ])

      tasks.run

      expect(executed).to eq([1, 2])
    end

    it "returns results for each task" do
      tasks = create_tasks([
        {title: "Task 1", task: -> {}},
        {title: "Task 2", task: -> {}}
      ])

      results = tasks.run

      expect(results.length).to eq(2)
      expect(results.first.title).to eq("Task 1")
      expect(results.first.status).to eq(:success)
    end

    it "captures errors" do
      tasks = create_tasks([
        {title: "Failing task", task: -> { raise "Oops!" }}
      ])

      results = tasks.run

      expect(results.first.status).to eq(:error)
      expect(results.first.error).to eq("Oops!")
    end

    it "continues after errors" do
      executed = []
      tasks = create_tasks([
        {title: "Fail", task: -> { raise "Error" }},
        {title: "Success", task: -> { executed << :ok }}
      ])

      tasks.run

      expect(executed).to eq([:ok])
    end

    it "renders output for each task" do
      tasks = create_tasks([
        {title: "My Task", task: -> {}}
      ])

      tasks.run

      expect(output.string).to include("My Task")
    end
  end
end
