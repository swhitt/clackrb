# frozen_string_literal: true

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

    context "with message-update callback" do
      it "passes a message-update callable to task procs that accept an argument" do
        received_message = nil
        tasks = create_tasks([
          {title: "Installing", task: ->(message) { received_message = message }}
        ])

        tasks.run

        expect(received_message).to respond_to(:call)
      end

      it "updates the spinner message when the callback is invoked" do
        tasks = create_tasks([
          {title: "Installing", task: ->(message) {
            message.call("Step 1...")
            # Allow spinner thread time to render the updated message
            sleep(Clack::Symbols::SPINNER_DELAY * 2)
            message.call("Step 2...")
            sleep(Clack::Symbols::SPINNER_DELAY * 2)
          }}
        ])

        tasks.run

        # Core::Spinner strips trailing dots and animates them separately
        expect(output.string).to include("Step 1")
        expect(output.string).to include("Step 2")
      end

      it "still works with task procs that take no arguments" do
        executed = false
        tasks = create_tasks([
          {title: "Simple", task: -> { executed = true }}
        ])

        tasks.run

        expect(executed).to be true
      end

      it "handles errors in tasks that use message-update" do
        tasks = create_tasks([
          {title: "Failing", task: ->(message) {
            message.call("Working...")
            raise "Boom!"
          }}
        ])

        results = tasks.run

        expect(results.first.status).to eq(:error)
        expect(results.first.error).to eq("Boom!")
      end
    end

    context "with enabled flag" do
      it "skips tasks with enabled: false" do
        executed = []
        tasks = create_tasks([
          {title: "Skipped", task: -> { executed << :skipped }, enabled: false},
          {title: "Runs", task: -> { executed << :ran }}
        ])

        tasks.run

        expect(executed).to eq([:ran])
      end

      it "does not include skipped tasks in results" do
        tasks = create_tasks([
          {title: "Skipped", task: -> {}, enabled: false},
          {title: "Runs", task: -> {}}
        ])

        results = tasks.run

        expect(results.length).to eq(1)
        expect(results.first.title).to eq("Runs")
      end

      it "does not render output for skipped tasks" do
        tasks = create_tasks([
          {title: "Invisible Task", task: -> {}, enabled: false}
        ])

        tasks.run

        expect(output.string).not_to include("Invisible Task")
      end

      it "defaults enabled to true when not specified" do
        executed = false
        tasks = create_tasks([
          {title: "Default", task: -> { executed = true }}
        ])

        tasks.run

        expect(executed).to be true
      end

      it "runs tasks with enabled: true" do
        executed = false
        tasks = create_tasks([
          {title: "Enabled", task: -> { executed = true }, enabled: true}
        ])

        tasks.run

        expect(executed).to be true
      end

      it "skips all tasks when all are disabled" do
        tasks = create_tasks([
          {title: "A", task: -> { raise "should not run" }, enabled: false},
          {title: "B", task: -> { raise "should not run" }, enabled: false}
        ])

        results = tasks.run

        expect(results).to be_empty
      end
    end
  end
end
