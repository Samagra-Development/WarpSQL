async function saveToFile(metrics, fs, path) {
  const filePath = path;
  const jsonData = JSON.stringify(metrics, null, 2);

  try {
    await fs.promises.writeFile(filePath, jsonData);
    console.log(`Metrics saved to ${filePath}`);
  } catch (error) {
    console.error(`Error saving metrics to ${filePath}: ${error}`);
  }
}

async function readFromFile(fs, path) {
  const filePath = path;
  try {
    const jsonData = await fs.promises.readFile(filePath);
    const metrics = JSON.parse(jsonData);
    return metrics;
  } catch (error) {
    console.error(`Error reading metrics from ${filePath}: ${error}`);
    return null;
  }
}

function parseSizeToBytes(value, unit) {
  let bytes;

  switch (unit) {
    case "KB":
      bytes = value * 1024;
      break;
    case "MB":
      bytes = value * 1024 * 1024;
      break;
    case "GB":
      bytes = value * 1024 * 1024 * 1024;
      break;
    default:
      throw new Error("Invalid size unit");
  }

  return bytes;
}

function formatBytes(bytes, decimals = 2) {
  if (bytes == null) return "Unknown";
  if (!+bytes) return "0 Bytes";

  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = [
    "Bytes",
    "KiB",
    "MiB",
    "GiB",
    "TiB",
    "PiB",
    "EiB",
    "ZiB",
    "YiB",
  ];

  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
}

async function captureExecOutput(
  exec,
  command,
  arguments,
  ignoreExitCode = false
) {
  let myOutput = "";
  let myError = "";

  const options = {};
  options.listeners = {
    stdout: (data) => {
      myOutput += data.toString();
    },
    stderr: (data) => {
      myError += data.toString();
    },
  };
  if (ignoreExitCode) {
    options.ignoreReturnCode = true;
  }
  await exec.exec(command, arguments, options);
  console.log(myOutput);
  return myOutput;
}

function calculatePercentageChange(currentValue, previousValue) {
  if (!previousValue || previousValue === 0) {
    return "";
  }

  const percentageChange =
    ((currentValue - previousValue) / previousValue) * 100;
  const colorIndicator =
    percentageChange > 0 ? ":small_red_triangle:" : ":small_red_triangle_down:";
  console.log(percentageChange);
  console.log(percentageChange.toFixed(2));
  const formattedChange = `[${percentageChange.toFixed(
    2
  )} %  ${colorIndicator}]`;
  return formattedChange;
}

function createIssueComment(
  imageType,
  commitSHA,
  imageSizeInBytes,
  metricToCompare
) {
  const currentSize = formatBytes(imageSizeInBytes);
  const previousSize = formatBytes(metricToCompare?.imageSize || null);
  const percentageChange = calculatePercentageChange(
    imageSizeInBytes,
    metricToCompare?.imageSize || null
  );

  const githubMessage = `### :bar_chart: ${imageType} Image Analysis  (Commit: ${commitSHA} )
  #### Summary
  
  - **Current Size:** ${currentSize} ${percentageChange}
  - **Previous Size :** ${previousSize}`;

  return githubMessage;
}

async function getPullNumber(github, workflow_run, context, core) {
  let head = `${workflow_run.actor.login}:${workflow_run.head_branch}`;
  let prNumber = (
    await github.rest.pulls.list({
      owner: context.repo.owner,
      repo: context.repo.repo,
      head: head,
    })
  ).data[0]?.number;
  if (prNumber != undefined) {
    console.log(`Found PR number ${prNumber} based on base and head branches`);
    core.exportVariable("pull_request_number", prNumber);
  } else {
    core.setFailed(
      `Action failed: Pull-Request Number NOt found with head: ${head}`
    );
  }

  console.log(prNumber);
  return prNumber;
}

module.exports = async ({ github, context, exec, core, fs }) => {
  let commitSHA = context.payload.workflow_run.head_sha;
  let imageSize = await captureExecOutput(exec, "docker", [
    "image",
    "list",
    "--format",
    "{{.Size}}",
    "smoketest-image",
  ]);
  let imageSizeInBytes = parseSizeToBytes(
    imageSize.trim().slice(0, -2),
    imageSize.trim().slice(-2)
  );
  let imageLayers = await captureExecOutput(exec, "docker", [
    "image",
    "history",
    "-H",
    "--format",
    "table {{.CreatedBy}} \\t\\t {{.Size}}",
    "smoketest-image",
  ]);
  const imageType = core.getInput("image-type", { required: true });

  const workspace = core.getInput("workspace", { required: true });

  if (context.payload.workflow_run.event == "pull_request") {
    const metricToCompare =
      (await readFromFile(fs, "image-metrics-" + imageType + ".json")) || {};

    let githubMessage = createIssueComment(
      imageType,
      commitSHA,
      imageSizeInBytes,
      metricToCompare
    );
    let issueNumber = await getPullNumber(
      github,
      context.payload.workflow_run,
      context,
      core
    );
    const comment = {
      body: githubMessage,
      issue_number: issueNumber,
    };
    const commentQueue = (await readFromFile(fs, "comments.json")) || [];
    commentQueue.push(comment);
    console.log(commentQueue);
    await saveToFile(commentQueue, fs, "comments.json");
  } else if (context.payload.workflow_run.event == "push") {
    const updatedMetric = {
      imageId: imageType,
      imageSize: imageSizeInBytes,
    };
    console.log(updatedMetric);
    await saveToFile(updatedMetric, fs, "image-metrics-" + imageType + ".json");
  }
};
